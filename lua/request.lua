local json = require("cloud/json")
local http = require("simplehttp")
local config = require("config")
http.TIMEOUT = 30  -- Increased timeout for LLM API calls

-- Your API token
local LLM_URL = config.LLM_URL
local LLM_TOKEN = config.LLM_TOKEN
local DEEPLX_URL = config.DEEPLX_URL

-- Function to call SiliconFlow LLM API
local function call_llm_api(text)
   local request_body = json.encode({
      model = "deepseek-chat",
      messages = {
         {
            role = "system",
            content = "你需要用尽可能简短的方式回答问题"
         },
         {
            role = "user",
            content = text
         }
      },
      stream = false,
      max_tokens = 512,
      stop = json.null,
      temperature = 0.7,
      top_p = 0.7,
      top_k = 50,
      frequency_penalty = 0.5,
      n = 1,
      response_format = {
         type = "text"
      }
   })
   
   local response, code, headers = http.request{
      url = LLM_URL,
      method = "POST",
      headers = {
         ["Authorization"] = "Bearer " .. LLM_TOKEN,
         ["Content-Type"] = "application/json"
      },
      data = request_body
   }
   
   if code ~= 200 then
      return "API请求失败，错误代码: " .. tostring(code)
   end
   
   local success, result = pcall(json.decode, response)
   if not success then
      return "解析API响应失败"
   end
   
   if result.choices and result.choices[1] and result.choices[1].message and result.choices[1].message.content then
      return result.choices[1].message.content
   else
      return "无法获取LLM响应"
   end
end

local function call_translate_api(sentence, src_lan, tgt_lan)
   local request_data = {
      source_lang = src_lan,
      target_lang = tgt_lan,
      text = sentence,
      quality = "normal"
   }
   local request_body = json.encode(request_data)

   local response, code, headers = http.request{
      url = DEEPLX_URL,
      method = "POST",
      headers = {
         ["Content-Type"] = "application/json",
         ["Content-Length"] = tostring(#request_body)
      },
      data = request_body
   }

   if code ~= 200 then
      return "API请求失败，错误代码: " .. tostring(code)
   end

   local success, result = pcall(json.decode, response)
   if not success then
      return "解析API响应失败"
   end

   return result.data
end

local function filter(input, env)
   local code = env.engine.context.input
   local codeLen = #code

   local count = 0
   
   if code:sub(-2) == "''" then
      for cand in input:iter() do
         if count < 3 then
            if count == 0 then
               yield(cand)
            elseif count == 1 then
               yield(Candidate("request", 0, codeLen, "输入t调用翻译", cand.comment))
            elseif count == 2 then
               yield(Candidate("request", 0, codeLen, "输入l调用大模型", cand.comment))
            end
            count = count + 1
         else
            yield(cand)
         end
      end
   elseif code:sub(-3) == "''t" then
      for cand in input:iter() do
         if count < 3 then
            count = count + 1
            -- Get the text from the candidate
            local text = call_translate_api(cand.text, "auto", "en")
            cand.comment = "🤖"
            yield(Candidate("translate", 0, codeLen, text, cand.comment))
         else
            yield(cand)
         end
      end
   elseif code:sub(-3) == "''l" then
      for cand in input:iter() do
         if count < 1 then
            count = count + 1
            text = call_llm_api(cand.text)
            cand.comment = "🤖"
            yield(Candidate("llm", 0, codeLen, text, cand.comment))
         else
            yield(cand)
         end
      end
   else
      for cand in input:iter() do
          yield(cand)
      end
  end
end

return filter
