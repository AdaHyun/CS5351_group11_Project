angular.module("taigaCICD")
.service("CICDService", [
  "$q", "$http"
  ($q, $http) ->

    # 触发新的CI/CD运行
    run: (ref, inputs) ->
      data = { ref: ref }
      if inputs
        try
          data.inputs = JSON.parse(inputs)
        catch error
          return $q.reject("Invalid JSON format in inputs")

      $http.post("/api/cicd/run/", data)
      .then (response) ->
        return response.data
      .catch (error) ->
        # 修正：后端返回 { "error": "错误信息" }
        errorMsg = error.data?.error || error.statusText || "未知错误"
        return $q.reject(errorMsg)

    # 获取运行快照
    snapshot: (run_id) ->
      $http.get("/api/cicd/runs/#{run_id}/")
      .then (response) ->
        return response.data
      .catch (error) ->
        # 修正：后端返回 { "error": "错误信息" }
        errorMsg = error.data?.error || error.statusText || "未知错误"
        return $q.reject(errorMsg)
])
