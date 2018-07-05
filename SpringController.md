controller

1 get 的controller采用的同步方法，返回ResponseEntity，比如kernel中的controller

    @RequestMapping(value = "/detail", method = RequestMethod.GET)
    @ResponseBody
    public ResponseEntity getApplications() {
        try {
            List<XApplication> appList = xApplicationsService.getFullAppList();

            XASIList xasiList = new XASIList(appList);
            return ResponseEntity.ok(xasiList);
        } catch (Exception e) {
            logger.error("get application detail error, cause : {}", e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("get app detail error.");
        }
    }
	
2 post 的controller采用的异步方法，返回 DeferredResult<ResponseEntity<?>>，比如Phoenixolap和collector中的controller

    @RequestMapping(value = "/api/v1/statistic/db", method = POST)
    @ResponseStatus(HttpStatus.ACCEPTED)
    public DeferredResult<ResponseEntity<?>> receiveDbStatistics(@RequestBody byte[] body) {
        DeferredResult<ResponseEntity<?>> result = new DeferredResult<>();
        try {
            DBStatistic statistic = new Gson().fromJson(new String(body, "UTF-8"), DBStatistic.class);

            xLogger.log("receive db  statistic :" + statistic);

            List<String> sqls = new UpsertDbStatisticTableAction().buildSql(statistic);

            if (!CollectionUtils.isEmpty(sqls)) {
                PhoenixDBUtil.store(sqls);
            }
        } catch (Exception e) {
            xLogger.error("receive db statistic error {}", e);

            result.setResult(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(""));

            return result;
        }

        result.setResult(SUCCESS);

        return result;
    }
