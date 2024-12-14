local json = require("cloud/json")
local make = require("cloud/trigger")
local http = require("simplehttp")
http.TIMEOUT = 3

local xn_sp2qp_table = {["aa"]="a",["ai"]="ai",["an"]="an",["ah"]="ang",["ao"]="ao",["ba"]="ba",["bd"]="bai",["bj"]="ban",["bh"]="bang",["bc"]="bao",["bw"]="bei",["bf"]="ben",["bg"]="beng",["bi"]="bi",["bx"]="bia",["bm"]="bian",["bl"]="biang",["bn"]="biao",["bp"]="bie",["bb"]="bin",["bk"]="bing",["bo"]="bo",["bu"]="bu",["ca"]="ca",["cd"]="cai",["cj"]="can",["ch"]="cang",["cc"]="cao",["ce"]="ce",["cw"]="cei",["cf"]="cen",["cg"]="ceng",["ia"]="cha",["id"]="chai",["ij"]="chan",["ih"]="chang",["ic"]="chao",["ie"]="che",["if"]="chen",["ig"]="cheng",["ii"]="chi",["is"]="chong",["iz"]="chou",["iu"]="chu",["ix"]="chua",["ik"]="chuai",["ir"]="chuan",["il"]="chuang",["iv"]="chui",["iy"]="chun",["io"]="chuo",["ci"]="ci",["cs"]="cong",["cz"]="cou",["cu"]="cu",["cr"]="cuan",["cv"]="cui",["cy"]="cun",["co"]="cuo",["da"]="da",["dd"]="dai",["dj"]="dan",["dh"]="dang",["dc"]="dao",["de"]="de",["dw"]="dei",["df"]="den",["dg"]="deng",["di"]="di",["dx"]="dia",["dm"]="dian",["dn"]="diao",["dp"]="die",["db"]="din",["dk"]="ding",["dq"]="diu",["ds"]="dong",["dz"]="dou",["du"]="du",["dr"]="duan",["dv"]="dui",["dy"]="dun",["do"]="duo",["ee"]="e",["ei"]="ei",["en"]="en",["eg"]="eng",["er"]="er",["fa"]="fa",["fj"]="fan",["fh"]="fang",["fw"]="fei",["ff"]="fen",["fg"]="feng",["fn"]="fiao",["fo"]="fo",["fs"]="fong",["fz"]="fou",["fu"]="fu",["ga"]="ga",["gd"]="gai",["gj"]="gan",["gh"]="gang",["gc"]="gao",["ge"]="ge",["gw"]="gei",["gf"]="gen",["gg"]="geng",["gs"]="gong",["gz"]="gou",["gu"]="gu",["gx"]="gua",["gk"]="guai",["gr"]="guan",["gl"]="guang",["gv"]="gui",["gy"]="gun",["go"]="guo",["ha"]="ha",["hd"]="hai",["hj"]="han",["hh"]="hang",["hc"]="hao",["he"]="he",["hw"]="hei",["hf"]="hen",["hg"]="heng",["hm"]="hm",["hq"]="hng",["hs"]="hong",["hz"]="hou",["hu"]="hu",["hx"]="hua",["hk"]="huai",["hr"]="huan",["hl"]="huang",["hv"]="hui",["hy"]="hun",["ho"]="huo",["ji"]="ji",["jx"]="jia",["jm"]="jian",["jl"]="jiang",["jn"]="jiao",["jp"]="jie",["jb"]="jin",["jk"]="jing",["js"]="jiong",["jq"]="jiu",["ju"]="ju",["jr"]="juan",["jt"]="jue",["jy"]="jun",["ka"]="ka",["kd"]="kai",["kj"]="kan",["kh"]="kang",["kc"]="kao",["ke"]="ke",["kw"]="kei",["kf"]="ken",["kg"]="keng",["ks"]="kong",["kz"]="kou",["ku"]="ku",["kx"]="kua",["kk"]="kuai",["kr"]="kuan",["kl"]="kuang",["kv"]="kui",["ky"]="kun",["ko"]="kuo",["la"]="la",["ld"]="lai",["lj"]="lan",["lh"]="lang",["lc"]="lao",["le"]="le",["lw"]="lei",["lg"]="leng",["li"]="li",["lx"]="lia",["lm"]="lian",["ll"]="liang",["ln"]="liao",["lp"]="lie",["lb"]="lin",["lk"]="ling",["lq"]="liu",["lo"]="lo",["ls"]="long",["lz"]="lou",["lu"]="lu",["lr"]="luan",["lt"]="lue",["ly"]="lun",["lo"]="luo",["lv"]="lv",["am"]="m",["ma"]="ma",["md"]="mai",["mj"]="man",["mh"]="mang",["mc"]="mao",["me"]="me",["mw"]="mei",["mf"]="men",["mg"]="meng",["mi"]="mi",["mm"]="mian",["mn"]="miao",["mp"]="mie",["mb"]="min",["mk"]="ming",["mq"]="miu",["mo"]="mo",["mz"]="mou",["mu"]="mu",["na"]="na",["nd"]="nai",["nj"]="nan",["nh"]="nang",["nc"]="nao",["ne"]="ne",["nw"]="nei",["nf"]="nen",["ng"]="neng",["aq"]="ng",["ni"]="ni",["nx"]="nia",["nm"]="nian",["nl"]="niang",["nn"]="niao",["np"]="nie",["nb"]="nin",["nk"]="ning",["nq"]="niu",["ns"]="nong",["nz"]="nou",["nu"]="nu",["nr"]="nuan",["nt"]="nue",["ny"]="nun",["no"]="nuo",["nv"]="nv",["oo"]="o",["ou"]="ou",["pa"]="pa",["pd"]="pai",["pj"]="pan",["ph"]="pang",["pc"]="pao",["pw"]="pei",["pf"]="pen",["pg"]="peng",["pi"]="pi",["px"]="pia",["pm"]="pian",["pn"]="piao",["pp"]="pie",["pb"]="pin",["pk"]="ping",["po"]="po",["pz"]="pou",["pu"]="pu",["qi"]="qi",["qx"]="qia",["qm"]="qian",["ql"]="qiang",["qn"]="qiao",["qp"]="qie",["qb"]="qin",["qk"]="qing",["qs"]="qiong",["qq"]="qiu",["qu"]="qu",["qr"]="quan",["qt"]="que",["qy"]="qun",["rj"]="ran",["rh"]="rang",["rc"]="rao",["re"]="re",["rf"]="ren",["rg"]="reng",["ri"]="ri",["rs"]="rong",["rz"]="rou",["ru"]="ru",["rx"]="rua",["rr"]="ruan",["rv"]="rui",["ry"]="run",["ro"]="ruo",["sa"]="sa",["sd"]="sai",["sj"]="san",["sh"]="sang",["sc"]="sao",["se"]="se",["sw"]="sei",["sf"]="sen",["sg"]="seng",["ua"]="sha",["ud"]="shai",["uj"]="shan",["uh"]="shang",["uc"]="shao",["ue"]="she",["uw"]="shei",["uf"]="shen",["ug"]="sheng",["ui"]="shi",["uz"]="shou",["uu"]="shu",["ux"]="shua",["uk"]="shuai",["ur"]="shuan",["ul"]="shuang",["uv"]="shui",["uy"]="shun",["uo"]="shuo",["si"]="si",["ss"]="song",["sz"]="sou",["su"]="su",["sr"]="suan",["sv"]="sui",["sy"]="sun",["so"]="suo",["ta"]="ta",["td"]="tai",["tj"]="tan",["th"]="tang",["tc"]="tao",["te"]="te",["tw"]="tei",["tg"]="teng",["ti"]="ti",["tm"]="tian",["tn"]="tiao",["tp"]="tie",["tk"]="ting",["ts"]="tong",["tz"]="tou",["tu"]="tu",["tr"]="tuan",["tv"]="tui",["ty"]="tun",["to"]="tuo",["wa"]="wa",["wd"]="wai",["wj"]="wan",["wh"]="wang",["ww"]="wei",["wf"]="wen",["wg"]="weng",["wo"]="wo",["ws"]="wong",["wu"]="wu",["xi"]="xi",["xx"]="xia",["xm"]="xian",["xl"]="xiang",["xn"]="xiao",["xp"]="xie",["xb"]="xin",["xk"]="xing",["xs"]="xiong",["xq"]="xiu",["xu"]="xu",["xr"]="xuan",["xt"]="xue",["xy"]="xun",["ya"]="ya",["yd"]="yai",["yj"]="yan",["yh"]="yang",["yc"]="yao",["ye"]="ye",["yi"]="yi",["yb"]="yin",["yk"]="ying",["yo"]="yo",["ys"]="yong",["yz"]="you",["yu"]="yu",["yr"]="yuan",["yt"]="yue",["yy"]="yun",["za"]="za",["zd"]="zai",["zj"]="zan",["zh"]="zang",["zc"]="zao",["ze"]="ze",["zw"]="zei",["zf"]="zen",["zg"]="zeng",["va"]="zha",["vd"]="zhai",["vj"]="zhan",["vh"]="zhang",["vc"]="zhao",["ve"]="zhe",["vw"]="zhei",["vf"]="zhen",["vg"]="zheng",["vi"]="zhi",["vs"]="zhong",["vz"]="zhou",["vu"]="zhu",["vx"]="zhua",["vk"]="zhuai",["vr"]="zhuan",["vl"]="zhuang",["vv"]="zhui",["vy"]="zhun",["vo"]="zhuo",["zi"]="zi",["zs"]="zong",["zz"]="zou",["zu"]="zu",["zr"]="zuan",["zv"]="zui",["zy"]="zun",["zo"]="zuo"}

local tongue_raising = {["u"]="s",["i"]="c",["v"]="z"}

local function xh_sp_code_2_qp(input)
   local result_table = {}
   for i = 1, #input, 2 do
      local pair = input:sub(i, i + 1)
      if i + 1 > #input then
         pair = input:sub(i)
      end
      table.insert(result_table, xn_sp2qp_table[pair] or pair)
   end
   return table.concat(result_table, "")
end

local function make_url(input, bg, ed)
   return 'https://olime.baidu.com/py?input=' .. input ..
      '&inputtype=py&bg='.. bg .. '&ed='.. ed ..
      '&result=hanzi&resultcoding=utf-8&ch_en=0&clientinfo=web&version=1'
end

local function translator(input, seg)
   -- 处理双拼
   local reply = http.request(make_url(xh_sp_code_2_qp(input), 0, 3))
   local _, j = pcall(json.decode, reply)
   if j.status == "T" and j.result and j.result[1] then
      for i, v in ipairs(j.result[1]) do
         local c = Candidate("simple", seg.start, seg.start + v[2], v[1], "🌤️")
         c.quality = 2
         if string.gsub(v[3].pinyin, "'", "") == string.sub(input, 1, v[2]) then
            c.preedit = string.gsub(v[3].pinyin, "'", " ")
         end
	      yield(c)
      end
   end
   -- 处理简拼
   local jp = ""
   -- 遍历输入字符串，每次迭代时添加当前字符和'%27'，%27是'的转义形式
   for i = 1, #input do
      jp = jp .. (tongue_raising[input:sub(i, i)] or input:sub(i, i))  .. "%27"
   end
   jp = jp:sub(1, #jp - 3)
   local reply = http.request(make_url(jp, 0, 2))
   local _, j = pcall(json.decode, reply)
   if j.status == "T" and j.result and j.result[1] then
      for i, v in ipairs(j.result[1]) do
         local c = Candidate("simple", seg.start, seg.start + v[2], v[1], "☁️")
         c.quality = 2
         if string.gsub(v[3].pinyin, "'", "") == string.sub(input, 1, v[2]) then
            c.preedit = string.gsub(v[3].pinyin, "'", " ")
         end
         yield(c)
      end
   end
end

return make("Control+y", translator)