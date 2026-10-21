# 0.9.4 最终成品验收

产品提交：`79602aed3fd1f6e092b5560bd8deb07fbf29f676`。本记录的测试脚本修正不改变产品成品。

致谢：感谢 [@ArtificialAngels](https://github.com/ArtificialAngels) 对第三方插件数据便携化（[#174](https://github.com/WSL043/DSH-Portable/pull/174)）及预发布内核下社区插件兼容性修复（[#175](https://github.com/WSL043/DSH-Portable/pull/175)）的原始贡献。

## 成品与安全

- CI 39652186374，39/39 项成功。GitHub Actions 终态更新延迟导致一个已完成的 Linux x64 job 保持 in_progress；保留原始日志后只复验该任务，attempt 2 恢复明确成功。Windows artifact 12371080775 的 ID、大小及摘要未变。
- Windows 离线包 128,739,252 字节，比 0.9.3 少 9,953 字节；SHA-256 `d98b0f11e96388ba3c10714b6d4a0f3219a409b7c85ef1cd05e7cc59a9c090c7`。
- 随包 Node 24.19.0；内核 0.2.1-rc.2；Image Viewer 0.1.15 / Chat Manager 1.5.16。43 个 launcher 模块与固定 Git 提交逐字节一致，无源码覆盖。
- 实际 DSH 消费者解析的 MCP client/core 均为 2.3.0，成品依赖上执行的 6 项重定向安全行为检查通过。
- shell contract 升为 2，拒绝仍含旧依赖的 contract 1 内核包；旧 rc.2 manifest 的成品选择结果为 core-awaiting-qualification，不允许下载应用。
- 源码测试 1178 通过、14 跳过，契约/更新定向测试 67 通过，生产依赖审计为 0。当前开放 CodeQL、Dependabot、密钥扫描告警均为 0；这不构成未知漏洞不存在的保证。
- 最终成品实际依赖另行盘点：610 个已安装 package.json，排除 1 个自有 private 桥接包后，609 个公开依赖实例、546 个包名（554 个 name@version）提交 npm 公告接口，HTTP 200、公告 0。私有桥接包由源码/CodeQL/原生行为验收覆盖。

## Windows 实机

均为最终 ZIP 内原生宿主及 WebView2，隔离用户数据，不调用付费模型。

- 启动转场、主题切换、最大化/全屏、重启、目录移动、关闭退出及托盘通过；完整首次冷启动首帧约 17.3 秒，复用运行时的移动前后冷启动约 6.54/6.86 秒。这是本机采样，不是重启电脑后的性能保证。
- 原生工作区选择和下载通过；浅深色设置、存储维护、更新页及中英文窄窗口旧市场入口通过。
- 默认官方 Discover 加载 50 个真实条目，配置索引来源正确，无页面异常，未安装插件，启用列表和依赖未变。
- 两款默认插件浅深色验收通过：图片标注/草稿保留、会话归档恢复、取消删除/确认删除、启停后输入可用。
- Recovery 18 个实际故障场景通过；普通/加密数据包导出、密码导入、支持报告生成通过。
- 真实已发布 0.9.3 → 0.9.4 运行中整包升级通过；模拟 WebView 占用后重试恢复、移动后重启、5 类隔离数据标记和插件版本保留通过。
- 实际 AgentLoop、官方 JSONL 保存、续写重开及中断日志恢复通过，原历史文件哈希保持不变。

## 验收工具修正及限制

原始失败均保留：本机 Git 工作区 CRLF 与 CI LF 的比较改为固定 Git blob；折叠侧栏按 aria-label 查找账号菜单；维护菜单先滚动到可点击位置；导入数据后的配置不符合首次引导/旧市场测试前提，改用同一成品的干净测试配置；独立 Discover 探针采用实际 role=tab/aria-selected。未删除产品断言，未重建或覆盖成品来通过测试。

两处通用定位修正已随工具提交 `5a574df` 进入 main，只有 9 行增加、2 行删除，无产品代码变化。其 CI 39658415409 attempt 2 全 39 项成功，四语言 CodeQL 39658414573 成功。首次构建恰遇 npm 新发布的 `@aws-sdk/types@3.975.0` 元数据可用但压缩包 404；真实下载恢复且 SHA-512 匹配后仅执行一次 failed-only 复验，原失败日志保留。发布仍固定原产品提交与 tag。

升级保留检查使用隔离标记，不代表真实跨机凭据迁移；本轮没有多屏/DPI 硬件矩阵、付费模型或新的 120 分钟长稳证据。不将以前长期待办改为已完成。

## 发布、内核与清理

- 首阶段发布 [39657864024](https://github.com/WSL043/DSH-Portable/actions/runs/39657864024) 先公开下载并暂缓更新源。11 个资产身份、10 条校验清单、9 个固定版本下载入口及两类 attestation 已核对；Windows ZIP 与本机验收成品摘要一致。启动器直链首次 HTTP 500 的证据保留，恢复后原 URL 实际下载摘要正确，未重传资产。
- 三个内核的五平台更新资格全部通过：[rc.1 / 39659031570](https://github.com/WSL043/DSH-Portable-Updates/actions/runs/39659031570)、[alpha.5 / 39662108989](https://github.com/WSL043/DSH-Portable-Updates/actions/runs/39662108989)、[rc.2 / 39664920820](https://github.com/WSL043/DSH-Portable-Updates/actions/runs/39664920820)。stable/candidate 十份目录、三十个条目均为 contract 2、Portable 0.9.4、资格源码 `79602ae`。rc.2 恢复从最新状态重新解析，rc.1/alpha.5 的 manifest 与其他资格记录保持不变。
- 上述三个 Windows 公开胶囊逐一验证 ZIP/胶囊/安装清单摘要、MCP client/core 2.3.0。实际公开依赖实例分别为 607、607、609，npm 公告接口均 HTTP 200、公告 0；未全量解压第二套运行时。其他平台的资格由各自构建、真实更新和启动检查覆盖，不把 Windows 的依赖盘点冒充全平台独立审计。
- alpha.4/alpha.3 由 [39668494206](https://github.com/WSL043/DSH-Portable-Updates/actions/runs/39668494206) 和 [39668763961](https://github.com/WSL043/DSH-Portable-Updates/actions/runs/39668763961) 在本次源码上重新记录插件 peer 阻断。两者从未提供给用户，正式发布门禁按既有规则记为 excused；没有跳过门禁或发布不兼容内核。
- 最终 [39668971046](https://github.com/WSL043/DSH-Portable/actions/runs/39668971046) 从固定 tag `v0.9.4` 成功开放更新源。双通道五平台回读 227 项通过，26 份唯一活动元数据签名使用固定产品提交的生产验签函数验证。成品客户端实际列出三个内核和产品 0.9.4；强制检查返回 current=latest=0.9.4、cached=false。README 两种语言由[原同步工作流](https://github.com/WSL043/DSH-Portable/actions/runs/39670036295)更新。
- 有限可用性欠项：旧 candidate 整包 `portable-manifest.json` 没有独立 `.sig`，显式调用这个旧入口时不能使用镜像回退；缺签名或错签名会拒绝镜像。正常客户端的五平台清单/索引签名有效，bootstrap 默认 stable，整包升级使用固定版本 URL。没有发现验签降级。
- 清理异常如实保留：本轮约 2.65 GiB 的隔离临时树在调用 `SendToRecycleBin` 后消失，但 C/D/F 回收站没有对应根目录记录，无法确认可恢复，不能列为“已移入回收站”。已停止进一步清理、禁用该一次性清理脚本，保留原错误和核验记录。此前基线副本的回收站记录仍存在。原便携版关键文件在操作后大小、SHA-256、ACL 均未改变；验收所属原生进程为 0。验收日志和 JSON 保留。
