# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

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
