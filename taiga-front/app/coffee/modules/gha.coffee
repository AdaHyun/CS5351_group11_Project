###
# CI/CD Visualization for GitHub Actions
# - File/YAML upload preview
# - Fetch recent runs/jobs from GitHub
###

taiga = @.taiga

class GHAService extends taiga.Service
    @.$inject = ["$tgHttp", "$tgUrls", "$q"]

    constructor: (@http, @urls, @q) ->
        super()

    previewFile: (file) ->
        fd = new FormData()
        fd.append('file', file)
        @http.request({
            method: 'POST',
            url: @urls.resolve('gha-preview'),
            data: fd,
            headers: { 'Content-Type': undefined },
            transformRequest: angular.identity
        })

    previewText: (yamlText) ->
        @http.request({
            method: 'POST',
            url: @urls.resolve('gha-preview'),
            data: { yaml: yamlText }
        })

    runs: ({owner, repo, workflow, per_page, token}) ->
        params = { owner, repo, workflow }
        if per_page? then params.per_page = per_page
        if token? and token.length > 0 then params.token = token
        @http.get(@urls.resolve('gha-github-runs'), params)


class GHAController
    @.$inject = ["$scope", "$tgLoading", "$translate", "GHAService"]

    constructor: (@scope, @loading, @translate, @gha) ->
        @scope.form = { yaml: '', owner: '', repo: '', workflow: '', per_page: 5, token: '' }
        @scope.preview = null
        @scope.runs = null
        @scope.error = null
        @scope.file = null

        @scope.onFileChange = (el) =>
            @scope.$apply =>
                @scope.file = el.files?[0] or null

        @scope.doPreview = =>
            @scope.error = null
            p = null
            if @scope.file?
                p = @gha.previewFile(@scope.file)
            else if @scope.form.yaml and @scope.form.yaml.length > 0
                p = @gha.previewText(@scope.form.yaml)
            else
                @scope.error = @translate.instant('GHA.ERROR_NO_CONTENT')
                return

            @loading.start()
            p.then((res) =>
                data = res?.data or res
                if angular.isString(data)
                    try
                        data = JSON.parse(data)
                    catch e
                        @scope.error = @translate.instant('GHA.ERROR_PARSE')
                        return
                @scope.preview = data
            ).catch((err) =>
                @scope.error = (err?.data?.detail) or err?.statusText or 'Error'
            ).finally(() =>
                @loading.finish()
            )

        @scope.fetchRuns = =>
            @scope.error = null
            {owner, repo, workflow, per_page, token} = @scope.form
            if !owner or !repo or !workflow
                @scope.error = @translate.instant('GHA.ERROR_MISSING_PARAMS')
                return
            @loading.start()
            @gha.runs({owner, repo, workflow, per_page, token}).then((res) =>
                data = res?.data or res
                if angular.isString(data)
                    try
                        data = JSON.parse(data)
                    catch e
                        @scope.error = @translate.instant('GHA.ERROR_PARSE')
                        return
                @scope.runs = data
            ).catch((err) =>
                @scope.error = (err?.data?.detail) or err?.statusText or 'Error'
            ).finally(() =>
                @loading.finish()
            )


module = angular.module("taigaGHA", ["taigaBase", "taigaResources"]) 
module.service("GHAService", GHAService)
module.controller("GHAController", GHAController)

