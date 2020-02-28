# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [0.4.0](https://github.com/ssube/prometheus-sql-adapter/compare/v0.3.3...v0.4.0) (2020-02-28)


### ⚠ BREAKING CHANGES

* **scripts:** no longer apply cat_name during setup script.
This view was creating a complete copy of metric_labels just
to break down the names. The name component utilities should be
used in place.

### Features

* **build:** add benchmark job ([a4569ad](https://github.com/ssube/prometheus-sql-adapter/commit/a4569ad9c43f01de1b33ba0c854d566cb80edc40))
* **build:** add code climate jobs ([6a3e289](https://github.com/ssube/prometheus-sql-adapter/commit/6a3e289def398d06c88cef746bccf8af173a25af))
* **build:** add go tests, run tests before images ([431da1b](https://github.com/ssube/prometheus-sql-adapter/commit/431da1bcb52d528c47a469827949ac7dcc1fe4e1))
* **build:** add jobs for jupyter images ([f8b822c](https://github.com/ssube/prometheus-sql-adapter/commit/f8b822cffb6a28580b504232815941b77b01f683))
* **build:** add pg_prometheus schema test jobs ([a24e6cf](https://github.com/ssube/prometheus-sql-adapter/commit/a24e6cf07f0460f459d0e46f1da87db70c6c7a88))
* **build:** add pgtap job for pg11 ([7d81b70](https://github.com/ssube/prometheus-sql-adapter/commit/7d81b70b9f7533a99a5c067136e9f4d0d1dc581a))
* **build:** add pgtap test job ([4b3bf5f](https://github.com/ssube/prometheus-sql-adapter/commit/4b3bf5f47f8ba4b0058a1dc5e2264827ea303138))
* **build:** collect go coverage ([2debb1e](https://github.com/ssube/prometheus-sql-adapter/commit/2debb1ecf971ad6d3cd69e7cbac446961d92b0ca))
* **build:** load compatibility views for schema testing ([9d98234](https://github.com/ssube/prometheus-sql-adapter/commit/9d98234bd3917136c84ba06f10566c6aa022bfe7))
* **build:** pull images before rebuilding to leverage layer cache ([c435514](https://github.com/ssube/prometheus-sql-adapter/commit/c435514829c353688047b5ca693ab5358f63584e))
* **build:** report coverage to codecov ([b599f89](https://github.com/ssube/prometheus-sql-adapter/commit/b599f89719313730165d8b0c390947d7e0071d3d))
* **build:** test compat views separately ([bb1596d](https://github.com/ssube/prometheus-sql-adapter/commit/bb1596d2cf8d4c30adbd47911ebec3b475feed8a))
* **container:** add git extension to jupyter lab image ([876c10c](https://github.com/ssube/prometheus-sql-adapter/commit/876c10ca528ffe7499cac7f45f560c8a537fe85d))
* **container:** add jupyter image for pg11 ([193cf27](https://github.com/ssube/prometheus-sql-adapter/commit/193cf27fe2d3b2b5c3cc527aee8983334bcdd029))
* **container:** add pg_prometheus extension to pgtap server images ([ba1924a](https://github.com/ssube/prometheus-sql-adapter/commit/ba1924a6619c12046498701823e82dba68050699))
* **container:** add pgtap container for schema tests ([1d9d52e](https://github.com/ssube/prometheus-sql-adapter/commit/1d9d52e37dead65a4105b648c40cd281385b893c))
* **container:** add self-configuring image (fixes [#49](https://github.com/ssube/prometheus-sql-adapter/issues/49)) ([79a5df2](https://github.com/ssube/prometheus-sql-adapter/commit/79a5df289eb54060c9c7659b0a277b04c12c9ad0))
* **docs:** add prometheus write config, example schema dump ([6d38609](https://github.com/ssube/prometheus-sql-adapter/commit/6d38609cbee28fcc2170453213062465155d9abe))
* **grafana/meta:** add catalog dashboard ([f90c8d3](https://github.com/ssube/prometheus-sql-adapter/commit/f90c8d33247f192892ae31adac1e37d8ae963d17))
* **grafana/meta:** add grafana alert dashboard ([aaae163](https://github.com/ssube/prometheus-sql-adapter/commit/aaae163addc2319938dbd5fb9bc2130ffcc6520d))
* **grafana/meta:** use timescale data for schema dash, show compression ratio ([eb865d8](https://github.com/ssube/prometheus-sql-adapter/commit/eb865d863f8a2691694a86ab29209e05a3943132))
* **jupyter:** add basic schema stats notebook ([#55](https://github.com/ssube/prometheus-sql-adapter/issues/55)) ([fc112ca](https://github.com/ssube/prometheus-sql-adapter/commit/fc112cac72659c578f6b2626e9abf0d412b8d6ae))
* **jupyter:** add compression ratios to schema notebook ([34c50a6](https://github.com/ssube/prometheus-sql-adapter/commit/34c50a65a62983fba15f3d45f9e113a3cd836c87))
* **jupyter:** add notebook for holt-winters load graphs ([5edcff6](https://github.com/ssube/prometheus-sql-adapter/commit/5edcff65ff35f12e286cf3ddfbfa06a59e2298d6))
* **jupyter:** add notebook to graph load by instance ([a77c0d0](https://github.com/ssube/prometheus-sql-adapter/commit/a77c0d081b3008ca623a547db4eff8c1c9349274))
* **jupyter:** provide tuned periods for holt-winters ([6899ec1](https://github.com/ssube/prometheus-sql-adapter/commit/6899ec1b0a8fa6987d52098db71866685d7934b0))
* **schema:** add debug report script (fixes [#47](https://github.com/ssube/prometheus-sql-adapter/issues/47)) ([c2fa435](https://github.com/ssube/prometheus-sql-adapter/commit/c2fa4350491f19155da0ab52a26a3113deeaea7c))
* **schema:** add schema version function ([#47](https://github.com/ssube/prometheus-sql-adapter/issues/47)) ([4f50d19](https://github.com/ssube/prometheus-sql-adapter/commit/4f50d19a7c58adfe9a578bbf243147098e6cf13b))
* **schema/caag:** add pod count caag ([f3b5efe](https://github.com/ssube/prometheus-sql-adapter/commit/f3b5efe30c766a0ed61798af7971bd7f7142c678))
* **schema/caag:** apply sql and grants ([954b1e4](https://github.com/ssube/prometheus-sql-adapter/commit/954b1e419ca97a6f99934e8b3c64b20673553ae0))
* **schema/cagg:** grafana alerts on hourly and daily basis (fixes [#36](https://github.com/ssube/prometheus-sql-adapter/issues/36)) ([c13a9b0](https://github.com/ssube/prometheus-sql-adapter/commit/c13a9b064d25de9136c425bdb2bb73492a0038d6))
* **schema/meta:** add compression ratio function ([d1798be](https://github.com/ssube/prometheus-sql-adapter/commit/d1798be14f4c29957fbcf41fa2cf33806090e3db))
* **schema/meta:** add schema size functions ([6cc0de9](https://github.com/ssube/prometheus-sql-adapter/commit/6cc0de9f9cecd327bf7c90022d9fd40a14538d70))
* **schema/meta:** include table details in debug report ([7e59c6d](https://github.com/ssube/prometheus-sql-adapter/commit/7e59c6dadc8fa0703a831dbceda8fbf740eb9c9e))
* **scripts:** optionally apply compatibility views when creating schema ([8468620](https://github.com/ssube/prometheus-sql-adapter/commit/846862023764d8a938bdc15eecb5ca910d615cb3))
* **test:** add initial pgtap test for rate_time ([2d9a164](https://github.com/ssube/prometheus-sql-adapter/commit/2d9a16443f2e1112129de98bb263d4edd80386ea))


### Bug Fixes

* **build:** adjust coverage paths to satisfy cc reporter ([51da714](https://github.com/ssube/prometheus-sql-adapter/commit/51da714206b048a507822cc8b7c23a065290ec89))
* **build:** codecov should depend on tests ([192b44b](https://github.com/ssube/prometheus-sql-adapter/commit/192b44b237afdf71d12268de0bca05c761503e92))
* **build:** enable timescale during tests ([93cc50a](https://github.com/ssube/prometheus-sql-adapter/commit/93cc50a20d97d682f5628b7239aaf179ce6ac5de))
* **build:** generate debug report during schema tests ([864893f](https://github.com/ssube/prometheus-sql-adapter/commit/864893f79068cbe6b6b27ac9b1326c3800ff4183))
* **build:** make benchmarks optional ([357c4ae](https://github.com/ssube/prometheus-sql-adapter/commit/357c4ae99cd45738cd83df89eb42ccbbd26e8d79))
* **build:** make targets for schema tests ([e5d6cb4](https://github.com/ssube/prometheus-sql-adapter/commit/e5d6cb478813c55401ca64fd8abbb38450e8da98))
* **build:** only apply compat views once ([37af889](https://github.com/ssube/prometheus-sql-adapter/commit/37af88952a7b0addeef8f2613f9be3df2461ec0f))
* **build:** report coverage for gitlab to match ([f35bbbc](https://github.com/ssube/prometheus-sql-adapter/commit/f35bbbc2e312e8d0c00a2859920ec06b4e15f88f))
* **build:** set postgres database for tests ([6625b17](https://github.com/ssube/prometheus-sql-adapter/commit/6625b17a41fcc33ec411cd9da3575500ab8f45f0))
* **build:** skip jupyter pg11 image ([7ffc79c](https://github.com/ssube/prometheus-sql-adapter/commit/7ffc79ca6e2a8ee29c05bc913abd637bc0f4a226))
* **build:** skip table suite during pg_prom compat tests ([a3ba31d](https://github.com/ssube/prometheus-sql-adapter/commit/a3ba31d086151c14e608ff52fd5c0ef54af39d49))
* **build:** use absolute path for climate report ([0cedc1c](https://github.com/ssube/prometheus-sql-adapter/commit/0cedc1c1d3e3bbcfe9de3f8d2d4fa6d88977cebc))
* **build:** use pgtap image for tests ([9764a14](https://github.com/ssube/prometheus-sql-adapter/commit/9764a141625cb64edb2a5a09d9ff81bd9eede764))
* **container:** add envsubst to pgtap test images ([51fe154](https://github.com/ssube/prometheus-sql-adapter/commit/51fe154d5684d52acc3b7eb97051c0df16ff79a7))
* **container:** add envsubst to server container for setup script ([af47f99](https://github.com/ssube/prometheus-sql-adapter/commit/af47f9953d70a48fcc4ae426c3b6d6602036dd46))
* **container:** add git and ssh to jupyter for cloning ([563cbd7](https://github.com/ssube/prometheus-sql-adapter/commit/563cbd7613904b1277ee949fab478f8d0b68830c))
* **container:** add schema and setup script to pgtap images ([990d80c](https://github.com/ssube/prometheus-sql-adapter/commit/990d80c8cf44952930eb3643ce3b7b6502db3db0))
* **container:** include package manifest in pg10 server ([7a80a89](https://github.com/ssube/prometheus-sql-adapter/commit/7a80a895ef62cb7729321ce19381ccfacf021e00))
* **container:** install envsubst correctly ([67a3225](https://github.com/ssube/prometheus-sql-adapter/commit/67a32255a64dcbe27976573c0e466a0cc1d7eea6))
* **container:** register common ssh keys to avoid clone hanging jupyter lab ([733a36c](https://github.com/ssube/prometheus-sql-adapter/commit/733a36cae99968a03be93d4196d4a63a6514f231))
* **docs:** add climate/coverage badges to readme ([1acb000](https://github.com/ssube/prometheus-sql-adapter/commit/1acb0008c9142af1edd64073bed5c6cff3f18e9f))
* **docs:** add troubleshooting steps to kubernetes deploy doc ([f7a0e5e](https://github.com/ssube/prometheus-sql-adapter/commit/f7a0e5e130078a123537f31100da51d032475ef2))
* **docs:** combine patterns into queries doc ([efb91ef](https://github.com/ssube/prometheus-sql-adapter/commit/efb91ef6c13ebb3abcf48db8d8a42c79d734dc77))
* **docs:** elaborate on alert and query patterns ([16001d8](https://github.com/ssube/prometheus-sql-adapter/commit/16001d8a9c79c31d6de5dcf2093671331c6744a7))
* **docs:** note jupyter in readme ([02d525a](https://github.com/ssube/prometheus-sql-adapter/commit/02d525a9c664056285cfdab844dc70e686025ee2))
* **docs:** pattern guide link ([d398778](https://github.com/ssube/prometheus-sql-adapter/commit/d39877877c045ffd4f6bc0c93737e446e73b84f4))
* **docs:** remove duplicate changelog entries ([6e85eb0](https://github.com/ssube/prometheus-sql-adapter/commit/6e85eb058f5561d0ed0f3db0be7f0f995838ff5d))
* **grafana/cluster:** time bucket instance history panels ([73aaab8](https://github.com/ssube/prometheus-sql-adapter/commit/73aaab803f2d39ea06c0e596c3d5b0883b9fb615))
* **grafana/cluster:** use bars for container limits ([473d1a8](https://github.com/ssube/prometheus-sql-adapter/commit/473d1a8921ac184ab8ea933cf48586771e8a93f3))
* **grafana/meta:** use compression ratio function ([a7aeeba](https://github.com/ssube/prometheus-sql-adapter/commit/a7aeebaf6bc8f8035ebeecec2f1a95d6e01f938b))
* **grafana/meta:** use schema size functions in schema dashboard ([0307cc3](https://github.com/ssube/prometheus-sql-adapter/commit/0307cc34632a765e8221fcfd0166f334caf4ff89))
* **jupyter:** graph 2 weeks of load at 4 hour increments ([8b6f08f](https://github.com/ssube/prometheus-sql-adapter/commit/8b6f08fa9ba336edcd0e32cc35c4855d1908967a))
* **jupyter:** invert compression ratio ([fdb27c3](https://github.com/ssube/prometheus-sql-adapter/commit/fdb27c310be14828e1570100e37065a955f10660))
* **jupyter:** make load forecast lines translucent ([e1d4116](https://github.com/ssube/prometheus-sql-adapter/commit/e1d4116e44d25c66669a4fbeab62d3817aff809e))
* **jupyter:** update instance load notebook to remove IP prefix ([7c0bd8b](https://github.com/ssube/prometheus-sql-adapter/commit/7c0bd8ba91186f805f595ca57dbf7bea68a14b89))
* **kubernetes:** doc grafana setup ([f8d0a8e](https://github.com/ssube/prometheus-sql-adapter/commit/f8d0a8e6a314bd770a440fda3361719b0bb2da5f))
* **kubernetes:** update image tags ([eedc4a5](https://github.com/ssube/prometheus-sql-adapter/commit/eedc4a5e2dc4580b4cf115cf3f5ad51c01c1801b))
* **kubernetes:** use self-configuring image ([3cdd551](https://github.com/ssube/prometheus-sql-adapter/commit/3cdd551e356b6c863ac227699bc2bb42d4b57b19))
* **postgres:** reduce log level for invalid/NaN values to debug ([#59](https://github.com/ssube/prometheus-sql-adapter/issues/59)) ([7eb4551](https://github.com/ssube/prometheus-sql-adapter/commit/7eb455103befd22855575a918683df4b6c1739e5))
* **schema:** correct catalog view names in grants, apply grafana alert cagg ([7965a36](https://github.com/ssube/prometheus-sql-adapter/commit/7965a36c89c1b389fe841e36ef8a4e8979cca6b6))
* **schema/cagg:** use correct rate function in alert cagg ([d15e9e9](https://github.com/ssube/prometheus-sql-adapter/commit/d15e9e9b794daac5399b131cc0c81e02667f4795))
* **schema/grant:** remove cat_name grants ([0a9c406](https://github.com/ssube/prometheus-sql-adapter/commit/0a9c40640ffb5277cdcea0875284e658a3a06c6e))
* **schema/meta:** add version info to debug report ([339f60c](https://github.com/ssube/prometheus-sql-adapter/commit/339f60c6cfe69bc69d38a0abe3a71079736b0caa))
* **scripts:** add shebang (fixes [#60](https://github.com/ssube/prometheus-sql-adapter/issues/60)) ([5b8d6c4](https://github.com/ssube/prometheus-sql-adapter/commit/5b8d6c4db561c8dc419d5b571e4546eab7a7fd0d))
* **scripts:** add timestamp to debug report ([3522957](https://github.com/ssube/prometheus-sql-adapter/commit/3522957f4e7992bf09367d8b735dd9c9fb9e40b9))
* **scripts:** apply time and rate utilities in order (fixes [#37](https://github.com/ssube/prometheus-sql-adapter/issues/37)) ([88771ae](https://github.com/ssube/prometheus-sql-adapter/commit/88771aec6a3a802827f638a16fb33eadb6047ba1))
* **scripts:** create meta functions after tables ([a449d1d](https://github.com/ssube/prometheus-sql-adapter/commit/a449d1d180acfcbc8d4086cecda91b985f68af05))
* **scripts:** make metric name catalog view optional ([75a9d58](https://github.com/ssube/prometheus-sql-adapter/commit/75a9d58a4a853ba3cc8f0dd2966f63f812c4ffdc))
* exclude notebooks from repo stats ([db36b24](https://github.com/ssube/prometheus-sql-adapter/commit/db36b240d79552532ed463cccf384920abe81744))
* **scripts:** make image build pre-pull optional ([7aeede7](https://github.com/ssube/prometheus-sql-adapter/commit/7aeede7058e36ae228a3d665f25215b985beb351))
* **test:** cover arg parsing ([5e278d7](https://github.com/ssube/prometheus-sql-adapter/commit/5e278d70f59638275f64498a8260fcd62904b258))
* **test:** cover empty client case ([3bdfcc3](https://github.com/ssube/prometheus-sql-adapter/commit/3bdfcc3ecf05af671684288f2009febe5c277c31))
* **test:** cover filter metric, get name ([02b9334](https://github.com/ssube/prometheus-sql-adapter/commit/02b93347440b8be207a71ccabc3c7b94ff8f70c1))
* **test:** cover interval seconds ([03310fc](https://github.com/ssube/prometheus-sql-adapter/commit/03310fcf646a07f6429dc92d8ed183a7e78f3892))
* **test:** cover lid, name helpers ([76b96a0](https://github.com/ssube/prometheus-sql-adapter/commit/76b96a098f79376698491e955b47a2f6eae0fb1b))
* **test:** cover metric view time filter ([ab197ee](https://github.com/ssube/prometheus-sql-adapter/commit/ab197eeb8163ff0d682d3cd5849a0b1aaaabd148))
* **test:** cover negative and reset cases within rate_time ([f763c0e](https://github.com/ssube/prometheus-sql-adapter/commit/f763c0eaafd2d204d36c1ced5b75521ff07a9412))
* **test:** cover rate_diff, rate_time ([986c502](https://github.com/ssube/prometheus-sql-adapter/commit/986c50227efcd8898ad9226a908b38cb6d167056))
* **test:** cover schema tables and indexes ([3ec6b3d](https://github.com/ssube/prometheus-sql-adapter/commit/3ec6b3dc5c87c939da8b4fa1679441bf380bcfff))
* **test:** cover send samples, postgres client name ([3462c9a](https://github.com/ssube/prometheus-sql-adapter/commit/3462c9a4ab73c9b8e806505802d2c46f2c5d5a8e))
* **test:** ensure metrics view exists ([8eb5bc2](https://github.com/ssube/prometheus-sql-adapter/commit/8eb5bc26fb69d170a12cca7ab031bc49a6bb684c))
* **test:** ensure samples hypertable has compression policy ([99ee1e5](https://github.com/ssube/prometheus-sql-adapter/commit/99ee1e52d87259e37c96cb0602ee4b96fecbe27f))
* **test:** round-trip a sample ([487018f](https://github.com/ssube/prometheus-sql-adapter/commit/487018fdd13645b72e6ba487aecc7795c17eceb6))
* **test:** set up partial schema for pg_prometheus tests ([a7e7595](https://github.com/ssube/prometheus-sql-adapter/commit/a7e7595bc5746942ef2d51e59a40a635c48e9bbc))

### [0.3.3](https://github.com/ssube/prometheus-sql-adapter/compare/v0.3.2...v0.3.3) (2019-12-15)


### Features

* **build:** add postgres 11 image ([b9ad26a](https://github.com/ssube/prometheus-sql-adapter/commit/b9ad26a80fd9b3722a8a4a60f90fc3185c9c79fc))
* **docs:** add patterns guide ([6275f0f](https://github.com/ssube/prometheus-sql-adapter/commit/6275f0f58f29406de19f374cdd8b56ff435c84ba))
* **docs:** describe rate with window functions ([1c1236c](https://github.com/ssube/prometheus-sql-adapter/commit/1c1236c66ebd5ecab2f2974623c05caf9cf041e8))
* **postgres:** make isolation level configurable ([#9](https://github.com/ssube/prometheus-sql-adapter/issues/9)) ([7ee3cb3](https://github.com/ssube/prometheus-sql-adapter/commit/7ee3cb3abae8e862f3138fd6310fa60a0a6abf7d))
* **postgres:** make ping time configurable ([#26](https://github.com/ssube/prometheus-sql-adapter/issues/26)) ([bd978c2](https://github.com/ssube/prometheus-sql-adapter/commit/bd978c2d42f35369c7a2930722ca7a4da532657f))
* **postgres:** make ping timeout configurable (fixes [#34](https://github.com/ssube/prometheus-sql-adapter/issues/34)) ([096f3c4](https://github.com/ssube/prometheus-sql-adapter/commit/096f3c41a4fe9cf5a86f84068d486fea64229771))
* **schema:** add catalog views for containers and instances ([8e13a5d](https://github.com/ssube/prometheus-sql-adapter/commit/8e13a5d4e6e5659badc01b4d5b61e402e4fc82f3))
* **schema:** add utility functions for instance host and metric name ([63cc839](https://github.com/ssube/prometheus-sql-adapter/commit/63cc839e2b841806066151c48e31686ce8754691))
* **schema:** rate and irate equivalents, smoothed version ([63c69a2](https://github.com/ssube/prometheus-sql-adapter/commit/63c69a2f58acbea46ceb3f1b9b866e27f2d7b6b4))
* **schema:** utility for seconds from text interval ([bf2c3da](https://github.com/ssube/prometheus-sql-adapter/commit/bf2c3da4c11d50cc65846ae382be4e1ad4f076ee))
* **schema/cagg:** add max usage, use rate_time util ([7c1d901](https://github.com/ssube/prometheus-sql-adapter/commit/7c1d90166c250ecec573bbb3bca614f87218d569))
* **schema/catalog:** add name catalog ([cd48ade](https://github.com/ssube/prometheus-sql-adapter/commit/cd48ade5b60f738a5675f774e56cb65778c4864f))
* **scripts:** apply catalog views during schema create ([bb44dfa](https://github.com/ssube/prometheus-sql-adapter/commit/bb44dfafa44edebe2adcf17a5bd84d911d5446b3))
* **scripts:** apply utils during schema create ([e022eb4](https://github.com/ssube/prometheus-sql-adapter/commit/e022eb426b5c7aff3d0a0ea5b7c307ab12592a41))


### Bug Fixes

* **build:** add npm ignore and publish registry ([a0a579c](https://github.com/ssube/prometheus-sql-adapter/commit/a0a579c5141dc7f56fb4db6de907c6be2a5c0bb0))
* **docs:** add group to window sub-select ([208b284](https://github.com/ssube/prometheus-sql-adapter/commit/208b2849c8c7f4b0982b02a06406b801fc8bf1aa))
* **docs:** describe schema subdirs ([be06b04](https://github.com/ssube/prometheus-sql-adapter/commit/be06b04980929ae8c8db63121b69dcd468315e13))
* **docs:** include used metric names and labels ([9b1770a](https://github.com/ssube/prometheus-sql-adapter/commit/9b1770a886281e15eaf93d52968df1d066db3b81))
* **docs:** make style a guide ([f3e1436](https://github.com/ssube/prometheus-sql-adapter/commit/f3e14363f4ffb48ff7149fd017daf0e660605ec7))
* **docs:** note views, order sections ([b4e0550](https://github.com/ssube/prometheus-sql-adapter/commit/b4e0550d491b457b384ec74d275016a041772abe))
* **docs:** update schema paths ([a6d8c4f](https://github.com/ssube/prometheus-sql-adapter/commit/a6d8c4f2abb37cfbf9852b69aef5fe1a2483f848))
* **docs:** use pipeline badge for master ([adc2686](https://github.com/ssube/prometheus-sql-adapter/commit/adc2686bb260d20999ca79bc3307ca856794d31a))
* **grafana/cluster:** update instance alerts with rate functions ([a61374f](https://github.com/ssube/prometheus-sql-adapter/commit/a61374ff6f92de61d71b23ddf97bcc83a58dff56))
* **postgres:** skip lid cache check before writing samples ([9c71e35](https://github.com/ssube/prometheus-sql-adapter/commit/9c71e351b1b573d7b31dc1d1ffd6d35f328c45b2))
* **postgres:** skipped labels should never be an error ([0f4e084](https://github.com/ssube/prometheus-sql-adapter/commit/0f4e08454f819bcb94d42df793a34c219c796855))
* **schema/catalog:** remove port from instance when it appears, include metric name in container catalog ([083d3d6](https://github.com/ssube/prometheus-sql-adapter/commit/083d3d69348382d6d0455af4092f94d51254c8ec))
* **schema/grant:** grant access to catalog views ([8319cfe](https://github.com/ssube/prometheus-sql-adapter/commit/8319cfeaa7707711d06f97c54ba50111d6119d6a))
* **scripts:** apply rate utils ([3409655](https://github.com/ssube/prometheus-sql-adapter/commit/34096551ed39960336a9be5308b82b33e767022a))
* bump default cache size to 100k items (small cluster) ([672b115](https://github.com/ssube/prometheus-sql-adapter/commit/672b115d3d9b0ed1b0b0e11f43d58b4a7d18effe))
* make label metric names consistent with samples ([aed9b40](https://github.com/ssube/prometheus-sql-adapter/commit/aed9b406fb7b37526d163791515585cd07c349d9))

### [0.3.2](https://github.com/ssube/prometheus-sql-adapter/compare/v0.3.1...v0.3.2) (2019-12-11)


### Features

* **build:** add CI and git info to binary ([301a794](https://github.com/ssube/prometheus-sql-adapter/commit/301a79403b95fc26d20bb8cef736297680576dae))
* **docs:** add schema readme, style guide ([115cc81](https://github.com/ssube/prometheus-sql-adapter/commit/115cc81cc8ea615b98cd993044a823a772186f9c))
* **grafana/cluster:** add container limit dashboard ([ccbc362](https://github.com/ssube/prometheus-sql-adapter/commit/ccbc3624848da96c06b15a51c650082cde3e8de6))
* **kubernetes/rules:** add container throttling ([165bd2a](https://github.com/ssube/prometheus-sql-adapter/commit/165bd2a7df819e03bdab82d398ad8001b5f4e1b4))
* **kubernetes/rules:** add prometheus lag ([3a1314f](https://github.com/ssube/prometheus-sql-adapter/commit/3a1314fb3336c08a6f19edd1001f10a9d8f95f5c))
* **postgres:** improve warning messages ([3cd2f3d](https://github.com/ssube/prometheus-sql-adapter/commit/3cd2f3d0c11d5bfe063528c198cae06fed72adc8))
* **schema:** promote compatibility views from benchmark ([29deacf](https://github.com/ssube/prometheus-sql-adapter/commit/29deacf758b8a86ba6900dc1b650f95c6f5600e9))
* **schema/alert:** add container spec & throttling queries ([6346529](https://github.com/ssube/prometheus-sql-adapter/commit/63465299cbd9beb5091527cf86e877c27fab7699))
* **schema/query:** add prometheus lag and sample rate ([3c8d205](https://github.com/ssube/prometheus-sql-adapter/commit/3c8d205b957d375732eaf5b09578612ce1229796))
* **schema/query:** count unique pods in labels ([ded3907](https://github.com/ssube/prometheus-sql-adapter/commit/ded39079194098f3aa4371ef03bb982092e944ef))


### Bug Fixes

* **build:** build image using make target ([c61ce71](https://github.com/ssube/prometheus-sql-adapter/commit/c61ce71d398ea639e39f27f01eaf4cbfe8312019))
* **docs:** list collected metrics ([5085777](https://github.com/ssube/prometheus-sql-adapter/commit/5085777e776d0d9b39e9bdcc90c0a5250fb2dc7a))
* **docs:** note aliases and time groups in sql style ([eac0341](https://github.com/ssube/prometheus-sql-adapter/commit/eac0341a18aedfd8c7c80e9a6755d266502c8d5f))
* **grafana/cluster:** add value and time range limits to container CPU throttling panel ([c8d9984](https://github.com/ssube/prometheus-sql-adapter/commit/c8d9984ca6110cbb6f986f6eff4d81c3cc083888))
* **postgres:** close statements before transactions ([6e21612](https://github.com/ssube/prometheus-sql-adapter/commit/6e2161216cf16fe7321286a3b562f49b22730641))
* **postgres:** log commit errors in labels transaction ([cc8f13e](https://github.com/ssube/prometheus-sql-adapter/commit/cc8f13e4492c66e88ec0d0befe8a912007bffb90))

### [0.3.1](https://github.com/ssube/prometheus-sql-adapter/compare/v0.3.0...v0.3.1) (2019-12-05)


### Features

* **benchmark:** add metrics_values equivalent view, ensure value chunks are same size ([2732bac](https://github.com/ssube/prometheus-sql-adapter/commit/2732bacdfba8efdb748c5f07f16344c4db4e6a17))
* **benchmark:** add script to get table sizes ([80de783](https://github.com/ssube/prometheus-sql-adapter/commit/80de783df2bb23d0ab08b1a0e66265101eb4121a))
* **build:** add makefile for common tasks ([481478f](https://github.com/ssube/prometheus-sql-adapter/commit/481478f361ac1d3306e26cef9dd29bd9b7eed2da))
* **container:** include schema ([c77f06f](https://github.com/ssube/prometheus-sql-adapter/commit/c77f06f10d24b45e97e9f7ad411003ef07fbcc5c))
* **docs:** add issue count badges ([3dfcd80](https://github.com/ssube/prometheus-sql-adapter/commit/3dfcd804ebf4f717e89c400ad63fa2c303277139))
* **grafana:** add basic cluster and meta dashboards ([60205cd](https://github.com/ssube/prometheus-sql-adapter/commit/60205cd7b1fd0f60b9b58e1eae5d12ab8ee8a257))
* **grafana:** add database variable to meta hypertables and schema ([a469ae1](https://github.com/ssube/prometheus-sql-adapter/commit/a469ae1aa56c5d22bcf8dbc28521361e48c7212d))
* **grafana:** use nodename in cluster history dashboard ([bf9b41f](https://github.com/ssube/prometheus-sql-adapter/commit/bf9b41f9ff1dd5099898a3bc28573988125f43bd))
* **query/alert:** add disk latency query ([4962344](https://github.com/ssube/prometheus-sql-adapter/commit/4962344c7b8a0a4d65334940b3c1a78114c8b96a))
* **schema:** add container cpu history query ([7ed9ec6](https://github.com/ssube/prometheus-sql-adapter/commit/7ed9ec69001dcb9860eab0560075d140ca3b525c))
* **schema:** index labels by (__name__, namespace, pod_name) for filtered dashboards (fixes [#24](https://github.com/ssube/prometheus-sql-adapter/issues/24)) ([7b8a15c](https://github.com/ssube/prometheus-sql-adapter/commit/7b8a15c46dfa889865355394d0d25ac26ebb0383))
* add github issue/PR templates ([ef532ee](https://github.com/ssube/prometheus-sql-adapter/commit/ef532ee6d7f531848005e7a835d80fb32a99d4c5))
* **schema:** invert metrics view to start with labels, add (name, time) index to samples ([9034a0d](https://github.com/ssube/prometheus-sql-adapter/commit/9034a0d7169ab2cf4d0e783de6942e7fcc23d4b2))
* **schema:** make statement timeouts variable ([099d60b](https://github.com/ssube/prometheus-sql-adapter/commit/099d60b666f697725b9d765e4a1f6fe2c526cf43))
* add benchmark adapter, dashboard, and queries ([4c547a5](https://github.com/ssube/prometheus-sql-adapter/commit/4c547a54496758f1ca342ce8ae59b062c786bf2d))
* enable compression for benchmark values ([7e7db2f](https://github.com/ssube/prometheus-sql-adapter/commit/7e7db2f62df92e55e06664623a0fff32b38b769e))
* pass metrics to client writer ([ff383d5](https://github.com/ssube/prometheus-sql-adapter/commit/ff383d51ec6121aeb0c715d100ffeb16e8750a14))


### Bug Fixes

* **build:** update package version ([43f2246](https://github.com/ssube/prometheus-sql-adapter/commit/43f224690f1d1b786aa267b28e647bac7e9cc361))
* **docs:** update metrics view, feature list ([6c22da5](https://github.com/ssube/prometheus-sql-adapter/commit/6c22da5d685c77331faf3e010c3ae8dfc21fddd2))
* **query/alert:** make alerts fully compatible with pg_prometheus ([d8e1c0b](https://github.com/ssube/prometheus-sql-adapter/commit/d8e1c0b8681be6d8087919692901fbcabbff11a2))
* **query/schema:** format chunk size ([a94e581](https://github.com/ssube/prometheus-sql-adapter/commit/a94e581c9d1a7abda1cea74de221f90687ff5b6a))
* **schema:** convert total retention to correct type for drop policy ([477a304](https://github.com/ssube/prometheus-sql-adapter/commit/477a3042eed994f82f7f4ea3ee41ccfcfabe3677))
* **schema:** grant adapter and grafana access to container caggs (fixes [#23](https://github.com/ssube/prometheus-sql-adapter/issues/23)) ([626cdbe](https://github.com/ssube/prometheus-sql-adapter/commit/626cdbefe4f99a60a83740c683fc7710ffe88a12))
* **schema:** include lid in pod name/namespace index ([b724e72](https://github.com/ssube/prometheus-sql-adapter/commit/b724e72fbe3878d68ce5d9b77f9f32f526621e0a))
* **schema/grant:** apply lowest statement timeout last ([a9fc78c](https://github.com/ssube/prometheus-sql-adapter/commit/a9fc78cfc9f1b009b784e238c1ba68d732e1eac7))
* **scripts:** create container views ([8c523f1](https://github.com/ssube/prometheus-sql-adapter/commit/8c523f1227db50d2f5928cafb2cfe3d90089b3b5))
* log allowed metric names during startup ([3c85a5d](https://github.com/ssube/prometheus-sql-adapter/commit/3c85a5d0e8df7ff4feb6fc4f205165fe6e0bfe61))

## [0.3.0](https://github.com/ssube/prometheus-sql-adapter/compare/v0.2.0...v0.3.0) (2019-11-29)


### Features

* **kubernetes:** add example deploy ([8b4bfb5](https://github.com/ssube/prometheus-sql-adapter/commit/8b4bfb53635a507874b796a0a2fb1eda0627a724))
* **labels:** use fnv1a metric fingerprint as label ID ([f18baa2](https://github.com/ssube/prometheus-sql-adapter/commit/f18baa2ecbe947c4717b553061b41464e979d128))
* **metrics:** observe ping times ([0dcda8c](https://github.com/ssube/prometheus-sql-adapter/commit/0dcda8c5e92fbff5df42f7d4b8dbb4c75a9c8df4))
* **postgres:** ping server during each metrics update ([327518b](https://github.com/ssube/prometheus-sql-adapter/commit/327518b7994e1960b3658a1090bf3694084c7b70))
* **query/schema:** add queries for unique timeseries by lid and name ([2ace37f](https://github.com/ssube/prometheus-sql-adapter/commit/2ace37ff24eb36ba46b37f1d78fa4f116df869c7))
* **schema:** args to set retention time ([c79d2cb](https://github.com/ssube/prometheus-sql-adapter/commit/c79d2cbb7a479670368f0b2a87a7af298db2e47b))
* **schema:** index labels by instance and name (fixes [#16](https://github.com/ssube/prometheus-sql-adapter/issues/16)) ([9659b62](https://github.com/ssube/prometheus-sql-adapter/commit/9659b621c43ff53cfe0fc75a39206e802e971654))
* **schema:** reduce lid to 64-bit integer ([fccf5c2](https://github.com/ssube/prometheus-sql-adapter/commit/fccf5c2d66aec7e16953730525041f5728db337d))
* **schema/query:** use late uname join in load alert ([fcaf073](https://github.com/ssube/prometheus-sql-adapter/commit/fcaf0734505548fdec8c6441e00e38dd3b61ed3d))


### Bug Fixes

* **docs:** add a brief getting started guide ([e9f55e5](https://github.com/ssube/prometheus-sql-adapter/commit/e9f55e5a41342365554894b9cdf5176f47314b4b))
* **docs:** add license ([0a2af69](https://github.com/ssube/prometheus-sql-adapter/commit/0a2af6994d4b6e9e9b46f74c45bcc795dfb71916))
* **docs:** add preface ([46f0975](https://github.com/ssube/prometheus-sql-adapter/commit/46f09752ea3823c25a3032ef46e7daebd1860ea3))
* **docs:** link to kubernetes deploy from getting started ([c34e911](https://github.com/ssube/prometheus-sql-adapter/commit/c34e911ca608dde5b730703fabdffb7318c1fa58))
* **docs:** note human role and grants ([bd9e67f](https://github.com/ssube/prometheus-sql-adapter/commit/bd9e67f2548c11e40fcb4cd4d0cbf6a2055f7618))
* **docs:** update readme description of lid ([e8f6114](https://github.com/ssube/prometheus-sql-adapter/commit/e8f61144fe1d669bcf35a1c3e1e9b5a7a8b470c9))
* **docs:** update readme schema ([d57a9b5](https://github.com/ssube/prometheus-sql-adapter/commit/d57a9b525bb194767dd7cd086d2d242b233fd302))
* **postgres:** do not ping server on every write ([9015205](https://github.com/ssube/prometheus-sql-adapter/commit/90152052fea45f3b29fde5cae9e9cdc06b5ce79e))
* **query/history:** add time filter to each part of historical union ([bffb6c3](https://github.com/ssube/prometheus-sql-adapter/commit/bffb6c37ed87f70a3f8cda7f633c5b87d573eac4))
* **schema:** apply timeout to grafana, allow humans to see samples ([0c7e64b](https://github.com/ssube/prometheus-sql-adapter/commit/0c7e64b12ced757f4fc8c389cae35d22f965c6a0))
* **schema:** improve nodename joins ([a0c6fcb](https://github.com/ssube/prometheus-sql-adapter/commit/a0c6fcb8328635fe46ba4d58e7dc732185500f35))
* **schema:** sort queries into subdirs ([6b2b32c](https://github.com/ssube/prometheus-sql-adapter/commit/6b2b32cc7c8266292288ff821c12790938f0cc51))
* store lid in lower half of uuid column ([a2be516](https://github.com/ssube/prometheus-sql-adapter/commit/a2be516032baec95c5861a522563ef586a4218e2))

## 0.2.0 (2019-11-28)


### Features

* **build:** add pipeline ([b4ee370](https://github.com/ssube/prometheus-sql-adapter/commit/b4ee370a33a4919e2918d837274348371b861ac5))
* **build:** set up standard-version for releases ([70f7372](https://github.com/ssube/prometheus-sql-adapter/commit/70f7372e2a6b999ddf88a357970f5d2438430549))
* **metrics:** report current cache length ([01287b8](https://github.com/ssube/prometheus-sql-adapter/commit/01287b8040f41212e0261ddc3261c506c3a3d626))
* **metrics:** report invalid and written sample counts ([7ca1314](https://github.com/ssube/prometheus-sql-adapter/commit/7ca13141619317c7936177e888c7507ca09c68c1))
* **metrics:** report new and skipped labels ([#3](https://github.com/ssube/prometheus-sql-adapter/issues/3)) ([0db40f2](https://github.com/ssube/prometheus-sql-adapter/commit/0db40f21ba7746518297acaa615448ed26a8c50f))
* **postgres:** retain lids in 2Q cache ([2e58188](https://github.com/ssube/prometheus-sql-adapter/commit/2e58188eb26405bff18530407dbc7fb50dafefb9))
* **schema:** add queries to get various sizes ([f22ce6a](https://github.com/ssube/prometheus-sql-adapter/commit/f22ce6abef7a25440e105ffb8edb40dadfc9d58f))
* **schema:** add setup and grant scripts ([f06a480](https://github.com/ssube/prometheus-sql-adapter/commit/f06a4800a5e7108fc9cbe3d2db72502aef6e7cd5))
* **schema:** compress chunks older than 6 hours, document results ([8ce88ec](https://github.com/ssube/prometheus-sql-adapter/commit/8ce88ec3f81ec959134d1c8811873d4a478e2a41))
* **schema:** limit high-resolution query range ([953d7d1](https://github.com/ssube/prometheus-sql-adapter/commit/953d7d1476457c114130579393a608e0dd5259a6))
* **schema:** make retention variable, add prune policy for cloud/enterprise ([c4c3aea](https://github.com/ssube/prometheus-sql-adapter/commit/c4c3aeac973ce2dc0f87a09060e78a91545ee501))
* **schema/grant:** add human developer role ([e97211a](https://github.com/ssube/prometheus-sql-adapter/commit/e97211aab07652624c83e20916c54646a31148ee))
* **schema/views:** add hourly load aggregate, example union query ([7618a3b](https://github.com/ssube/prometheus-sql-adapter/commit/7618a3b70ab76b449fe067247f0c43f3b68eac91))


### Bug Fixes

* **build:** list renovate as update in changelog ([dfcb177](https://github.com/ssube/prometheus-sql-adapter/commit/dfcb17781787b8b88e6cf84afd51fb71b2cfc9f8))
* **build:** lock gomods ([635c9f2](https://github.com/ssube/prometheus-sql-adapter/commit/635c9f225cf712701719ea36dc579f17cfcab1e8))
* **build:** push images ([443a0cb](https://github.com/ssube/prometheus-sql-adapter/commit/443a0cbea221064857dea07d73ba0fee06b60d56))
* **docs:** explain label ID ([e674dcf](https://github.com/ssube/prometheus-sql-adapter/commit/e674dcfd2f5bf0c0580ade03d5284d90ca41a921))
* **docs:** note schema in readme ([6deeb19](https://github.com/ssube/prometheus-sql-adapter/commit/6deeb19ffad7ee0a6e535d02616cfb10ccf3f4a6))
* **schema:** create extension with tables ([8645462](https://github.com/ssube/prometheus-sql-adapter/commit/864546270934a4bd9e243c700aa63b75f87c35ac))
* **schema:** grant adapter write to long load agg ([8989fd6](https://github.com/ssube/prometheus-sql-adapter/commit/8989fd6e75bacd458f57f4125c3dbf1186c7035d))
* **schema:** include samples name/lid index ([c857279](https://github.com/ssube/prometheus-sql-adapter/commit/c8572793dae2738c98608a8d9b0e04f2073087e4))
* **schema:** remove unused partitioning column ([cfd4c4b](https://github.com/ssube/prometheus-sql-adapter/commit/cfd4c4b0cf3c18da7603173408840b89f0966ae4))
* **scripts:** apply prune policy script ([e4213b7](https://github.com/ssube/prometheus-sql-adapter/commit/e4213b7517a6cf0021bdfc2ec885837e2b83d65f))
* qualify metrics with 'adapter' namespace ([#3](https://github.com/ssube/prometheus-sql-adapter/issues/3)) ([def5b21](https://github.com/ssube/prometheus-sql-adapter/commit/def5b2141e68b9366ae64c0f6803087bf6dbdec1))
* **schema/query:** correct view names for instance history ([25da54b](https://github.com/ssube/prometheus-sql-adapter/commit/25da54bf35a179dfdb6a7032f1a59277a06adb4c))
