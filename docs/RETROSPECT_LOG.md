# Retrospect Log

## 模板
- 日期：
- 站点：
- 问题现象：
- 根因：
- 修复策略：
- 最终规则沉淀：
- 影响范围：
- 待办：

## 2026-03-04 / shukuge
- 问题现象：章节标题可提取，但链接在部分客户端场景丢失。
- 根因：相对 list 上下文下，`text()`、`@href` 在香色运行时存在兼容差异。
- 修复策略：章节字段统一改为 `title=//text()`，`url=//@href`，`detailUrl=//@href`。
- 最终规则沉淀：即使 list 已定位到 `<a>`，章节字段仍优先双斜杠写法。
- 影响范围：chapterList 解析规则、skill 与项目文档。
- 待办：后续新站点统一按该规则起步。

## 2026-03-04 / web-validator
- 问题现象：缺少可视化、可回放、可导出的书源自动检测平台，人工调试成本高。
- 根因：现有流程以离线脚本和手工验证为主，缺少统一执行引擎与报告标准。
- 修复策略：在 `apps/web-validator` 落地独立 Web 项目，统一实现：
  - `source/normalize`、`validate/run`、`validate/step`、`source/patch`、`source/export`
  - `DOM + requestInfo @js + 字段 ||@js` 规则执行
  - `live/fixture` 双模式
  - 半自动 patch（`text()->//text()`、`@href->//@href` 等）
- 最终规则沉淀：第一版仅覆盖 `text` 类书源，旧式 `JSParser/requestJavascript/responseJavascript` 先识别告警，不做执行。
- 影响范围：新增 web 模块、文档入口、测试回归、报告存储路径。
- 待办：第二期补充旧引擎 JSParser 兼容与批量检测队列。

## 2026-03-04 / deqixs
- 问题现象：
  - 中文关键词搜索在客户端偶发请求异常或无结果。
  - 分类（如玄幻）加载慢，甚至不返回。
  - 部分流程提示“找不到url”。
  - 正文请求“网络错误”，或接口返回成功但正文仍为空。
- 根因：
  - `searchBook` 使用 `POST` 时，部分客户端对中文参数编码不稳定。
  - `bookWorld` 配置 `nextPageUrl + 高 maxPage` 导致连续翻页请求，触发超时。
  - `requestInfo` 中 URL 清洗写法 `replace(/\\//g,'/')` 在 JSON+JS 场景转义易出错。
  - 搜索存在“精确命中直达详情页”场景，纯 list 字段无法稳定提供后续 URL。
  - 章节正文不是首屏 DOM，而是两跳接口：
    - 第一步 `scripts/chapter.js.php` 产出 `chapterToken/timestamp/nonce`
    - 第二步 `modules/article/ajax2.php` 返回 JSON 正文
  - `ajax2.php` 对请求头有校验：缺 `X-Requested-With` 或 `Referer` 不是章节 URL，会返回“仅支持网页端访问/不支持该客户端访问”。
  - 章节 `content` 规则若遇到 `chapterToken` 就提前 `return ''`，会误杀“脚本 + JSON 混合响应”场景。
  - 部分链路里 `queryInfo` 缺字段时，`requestInfo` 未回退 `params.responseUrl`，导致“找不到url”。
- 修复策略：
  - 搜索改为 `GET + encodeURIComponent(params.keyWord)`。
  - 分类改为按 `pageIndex` 单页请求，移除 `nextPageUrl` 自动连翻。
  - URL 清洗统一改为 `split('\\\\/').join('/')`。
  - `searchBook` 保留 list 相对 `detailUrl`，并补充 `url` 兜底（canonical/meta）。
  - `bookDetail/chapterList/chapterContent.requestInfo` 增加 `params.responseUrl` 回退。
  - 章节正文改为两跳接口方案：
    - 第一跳从章节 URL 请求 `chapter.js.php`
    - 第二跳请求 `ajax2.php`，动态注入 `X-Requested-With: XMLHttpRequest` 与 `Referer: 当前章节URL`
  - 正文解析规则改为“先尝试 JSON 解析，再正则兜底提取 `content` 字段”，并删除 `chapterToken` 早退逻辑。
- 最终规则沉淀：
  - list 上下文字段优先，页面级兜底仅用于 `url` 补充，不覆盖 list 主字段。
  - 中文搜索优先 GET 编码方案。
  - 分类禁止默认深翻页策略。
  - 对“token 换正文”接口，必须把请求头策略写进 `chapterContent.requestInfo`，不要只依赖全局 `httpHeaders`。
  - `chapterContent.content` 不能用“看到 token 就返回空”的短路判断，必须优先判断是否已有可解析 JSON 正文。
  - URL 链路任何一步都保留 `params.responseUrl` 回退，降低“找不到url”概率。
- 影响范围：
  - `deqixs` 成品书源规则；
  - 项目文档与维护工作流检查项。
- 待办：
  - 将“章节两跳接口 + 动态请求头 + 混合响应解析”加入 web-validator 自动检查。

## 2026-03-05 / 66shuba
- 问题现象：
  - 页面有“请先登录”提示，初看像是详情/阅读被拦截。
  - 章节接口偶发返回 `code=0` 但正文是“网络开小差了，请稍后再试”。
  - 目录里混有非正文项，首条可能不是可读章节。
- 根因：
  - 站点是“前端壳 + JSON API”模式，真实数据主要来自：
    - `/api/novel/search`
    - `/api/novel/detail/{bookId}`
    - `/api/novel/catalog/{bookId}`
    - `/api/novel/chapter/{bookId}/{chapterId}`（VIP 用 `/api/novel/vip-chapter/...`）
  - `catalog` 里存在哨兵章节（如 `C=-10000`，版权信息），若不过滤会影响首章定位。
  - 部分章节源站缓存/限流异常时，会返回占位文本而非真实正文，即使业务 `code=0`。
- 修复策略：
  - 书源改为 API-first（`responseFormatType=json`），不依赖详情/阅读页 DOM。
  - `searchBook.list` 对 `CardList -> Body -> ItemData` 做 JS 扁平化，并过滤 `ItemType===0`。
  - `chapterList.list` 过滤 `C/chapterId/id <= 0` 的章节节点。
  - `chapterContent.requestInfo` 统一从 read URL 提取 `bookId/chapterId` 组装 API URL。
  - 正文清洗时保留“占位正文识别”检查：`网络开小差` 属于上游返回，不是解析器空内容。
- 最终规则沉淀：
  - 遇到 API-first 站点，优先走 JSON 接口链路，页面 DOM 仅作辅助定位。
  - 目录必须做“正文章节有效性过滤”（正整型章节 id）。
  - `code=0` 不等于正文有效；需增加占位文本判定与重试/换章排障。
  - 分类若无独立 API，可用关键词分类（`requestFilters.keyword`）稳定替代。
- 影响范围：
  - 新增 `66shuba` 成品书源；
  - 更新 skill 与文档中的 JSON API 站点开发规范。
- 待办：
  - 在 web-validator 增加“占位正文关键字”提示（如“网络开小差了”）。

## 2026-03-05 / sudugu
- 问题现象：
  - 部分章节会被误当作“有下一页”持续翻页，最终跳到下一章或目录。
  - 分类第 2 页如果按 `p-2` 猜路径，会抓到不相关列表或返回异常页面。
- 根因：
  - 章节底部导航结构复用同一节点位（`上一章/目录/下一页或下一章`），仅按文案匹配不稳定。
  - 同站点存在多种分页 URL 形态（目录与分类不同），盲猜模板易错。
- 修复策略：
  - `chapterContent.nextPageUrl` 改为“右侧导航位 + 同章分页守卫”：
    - 解析当前/候选 URL 为 `/{bookId}/{chapterId}(-{page})?.html`
    - 仅 `bookId/chapterId` 一致且 `nextPage > currentPage` 才翻页
  - 分类统一按 `pageIndex` 构造 `/{cat}/{page}.html`，不套用 `p-2`。
- 最终规则沉淀：
  - DOM 站正文分页必须做“同章守卫”，不能只靠 `contains(text(),'下一页')`。
  - 分页路径必须来自真实站点验证（或真实 next link），禁止猜 URL 规则。
- 影响范围：
  - `sudugu` 成品规则；
  - skill 与通用文档中的分页策略章节。
- 待办：
  - 在 web-validator 增加“nextPageUrl 跨章检测”自动告警。

## 2026-03-05 / shuhaoxs
- 问题现象：
  - 站内没有稳定搜索接口，首页搜索入口直接跳到外部域。
  - 目录接口翻页时出现“越界页重复末页”或“短书重复第 1 页”。
  - 正文页底部同时存在“下一页/下一章”位，容易误翻跨章。
- 根因：
  - 搜索链路被外部服务接管，且结果链接是前端加密跳转（`toUrl/openUrl`），不是明文详情 URL。
  - 外部跳转解密依赖 `CryptoJS + UA + 动态页面变量`，在书源运行时不保证稳定复现。
  - `loadChapterPage` 接口对页码越界没有“空列表”语义，导致仅按 `list.length` 翻页会死循环或重复。
- 修复策略：
  - 搜索采用站内可用优先：`searchBook` 用“分类页遍历 + 关键词过滤”做 fallback。
  - 详情字段改为 `og:*` 优先，DOM 作为兜底。
  - `chapterList` 对 `chapterorder` 增加页范围校验（每页 100）：
    - 仅接受当前页应有序号段；
    - `nextPageUrl` 需满足“首条序号匹配当前页起点 + 当前页满 100 条”。
  - `chapterContent.nextPageUrl` 增加同章分页守卫，仅允许 `/{aid}-{cid}-{p}.html` 且 `p` 递增。
- 最终规则沉淀：
  - 外部搜索若为加密跳转链路，优先降级到站内可维护方案，不把不稳定解密链路作为默认主搜索。
  - 目录分页接口不能只看“有数据就翻页”，必须叠加“数据是否属于当前页”的语义校验。
  - 正文翻页守卫必须严格区分“下一页”和“下一章”。
- 影响范围：
  - 新增 `shuhaoxs` 成品书源；
  - 更新 skill 与文档中的“外部搜索/目录分页防重复”规则。
- 待办：
  - 在 web-validator 增加“目录分页重复页检测”（同一章节序号段重复返回）告警。
