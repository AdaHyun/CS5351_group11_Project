angular.module("taigaCICD")
.controller("CICDController", [
  "$scope", "$interval", "$timeout", "CICDService", "$log"
  ($scope, $interval, $timeout, CICDService, $log) ->
    vm = @

    # 状态初始化
    vm.form = {
      ref: "master"
      inputs: ""
    }
    vm.runs = []
    vm.error = null
    vm.isLoading = false
    vm.isPolling = false
    vm.simulationIntervals = {}

    # 轮询控制
    vm.POLL_INTERVAL_MS = 500
    vm.runStartTimes = {}
    vm.runElapsedTimes = {}

    # 已使用的 run_id 记录
    vm.usedRunIds = []

    # 多个静态示例数据
    vm.staticDataSets = [
      {
        "run_id": 19471301034,
        "jobs": [
          {
            "job_name": "dummy",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Dummy ticking", "duration": 30.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          },
          {
            "job_name": "build (3.10)",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run actions/checkout@v3", "duration": 1.0},
              {"name": "Set up Python 3.10", "duration": 0.0},
              {"name": "Install deps (pip & ruff & coverage)", "duration": 6.0},
              {"name": "Lint with Ruff (non-blocking)", "duration": 0.0},
              {"name": "Simulate long step (pre-test ticking)", "duration": 30.0},
              {"name": "Test with pytest + coverage", "duration": 1.0},
              {"name": "Generate Coverage Report", "duration": 1.0},
              {"name": "Simulate post-test ticking", "duration": 30.0},
              {"name": "Post Set up Python 3.10", "duration": 1.0},
              {"name": "Post Run actions/checkout@v3", "duration": 1.0}
            ]
          },
          {
            "job_name": "build (3.11)",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run actions/checkout@v3", "duration": 1.0},
              {"name": "Set up Python 3.11", "duration": 1.0},
              {"name": "Install deps (pip & ruff & coverage)", "duration": 5.0},
              {"name": "Lint with Ruff (non-blocking)", "duration": 0.0},
              {"name": "Simulate long step (pre-test ticking)", "duration": 30.0},
              {"name": "Test with pytest + coverage", "duration": 2.0},
              {"name": "Generate Coverage Report", "duration": 1.0},
              {"name": "Simulate post-test ticking", "duration": 30.0},
              {"name": "Post Set up Python 3.11", "duration": 1.0},
              {"name": "Post Run actions/checkout@v3", "duration": 1.0}
            ]
          },
          {
            "job_name": "integration",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Aggregate Stage (final ticking)", "duration": 30.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          },
          {
            "job_name": "summary",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run summary", "duration": 1.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          }
        ]
      },
      {
        "run_id": 19470428938,
        "jobs": [
          {
            "job_name": "dummy",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Dummy ticking", "duration": 30.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          },
          {
            "job_name": "build (3.10)",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run actions/checkout@v3", "duration": 1.0},
              {"name": "Set up Python 3.10", "duration": 0.0},
              {"name": "Install deps (pip & ruff & coverage)", "duration": 6.0},
              {"name": "Lint with Ruff (non-blocking)", "duration": 0.0},
              {"name": "Simulate long step (pre-test ticking)", "duration": 30.0},
              {"name": "Test with pytest + coverage", "duration": 1.0},
              {"name": "Generate Coverage Report", "duration": 1.0},
              {"name": "Simulate post-test ticking", "duration": 30.0},
              {"name": "Post Set up Python 3.10", "duration": 1.0},
              {"name": "Post Run actions/checkout@v3", "duration": 1.0}
            ]
          },
          {
            "job_name": "build (3.11)",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run actions/checkout@v3", "duration": 1.0},
              {"name": "Set up Python 3.11", "duration": 1.0},
              {"name": "Install deps (pip & ruff & coverage)", "duration": 5.0},
              {"name": "Lint with Ruff (non-blocking)", "duration": 0.0},
              {"name": "Simulate long step (pre-test ticking)", "duration": 30.0},
              {"name": "Test with pytest + coverage", "duration": 2.0},
              {"name": "Generate Coverage Report", "duration": 1.0},
              {"name": "Simulate post-test ticking", "duration": 30.0},
              {"name": "Post Set up Python 3.11", "duration": 1.0},
              {"name": "Post Run actions/checkout@v3", "duration": 1.0}
            ]
          },
          {
            "job_name": "integration",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Aggregate Stage (final ticking)", "duration": 30.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          },
          {
            "job_name": "summary",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run summary", "duration": 1.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          }
        ]
      },
      {
        "run_id": 19467413438,
        "jobs": [
          {
            "job_name": "dummy",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Dummy ticking", "duration": 30.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          },
          {
            "job_name": "build (3.10)",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run actions/checkout@v3", "duration": 1.0},
              {"name": "Set up Python 3.10", "duration": 0.0},
              {"name": "Install deps (pip & ruff & coverage)", "duration": 7.0},
              {"name": "Lint with Ruff (non-blocking)", "duration": 0.0},
              {"name": "Simulate long step (pre-test ticking)", "duration": 31.0},
              {"name": "Test with pytest + coverage", "duration": 1.0},
              {"name": "Generate Coverage Report", "duration": 1.0},
              {"name": "Simulate post-test ticking", "duration": 30.0},
              {"name": "Post Set up Python 3.10", "duration": 1.0},
              {"name": "Post Run actions/checkout@v3", "duration": 1.0}
            ]
          },
          {
            "job_name": "build (3.11)",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run actions/checkout@v3", "duration": 1.0},
              {"name": "Set up Python 3.11", "duration": 1.0},
              {"name": "Install deps (pip & ruff & coverage)", "duration": 7.0},
              {"name": "Lint with Ruff (non-blocking)", "duration": 0.0},
              {"name": "Simulate long step (pre-test ticking)", "duration": 30.0},
              {"name": "Test with pytest + coverage", "duration": 1.0},
              {"name": "Generate Coverage Report", "duration": 1.0},
              {"name": "Simulate post-test ticking", "duration": 30.0},
              {"name": "Post Set up Python 3.11", "duration": 1.0},
              {"name": "Post Run actions/checkout@v3", "duration": 1.0}
            ]
          },
          {
            "job_name": "integration",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Aggregate Stage (final ticking)", "duration": 30.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          },
          {
            "job_name": "summary",
            "steps": [
              {"name": "Set up job", "duration": 1.0},
              {"name": "Run summary", "duration": 1.0},
              {"name": "Complete job", "duration": 1.0}
            ]
          }
        ]
      }
    ]

    # 获取可用的真实 run_id
    vm.getAvailableRealRunId = ->
      availableIds = vm.staticDataSets
        .map((data) -> data.run_id)
        .filter((runId) -> vm.usedRunIds.indexOf(runId) == -1)
      
      if availableIds.length > 0
        return availableIds[0]
      else
        return null

    # 获取对应的静态数据
    vm.getStaticDataByRunId = (runId) ->
      return vm.staticDataSets.find((data) -> data.run_id == runId)

    # 生成唯一的 run_id（当真实 run_id 用完时使用）
    vm.generateUniqueRunId = ->
      baseId = vm.staticDataSets[0].run_id
      timestamp = new Date().getTime()
      return baseId + timestamp % 100000

    # 处理静态数据并添加模拟状态
    vm.processStaticData = (staticData, useRealId = true) ->
      $log.debug("处理静态数据:", staticData)
      
      # 计算总持续时间
      totalDuration = 0
      staticData.jobs.forEach (job) ->
        job.total_duration = 0
        job.steps.forEach (step) ->
          job.total_duration += step.duration
        totalDuration = Math.max(totalDuration, job.total_duration)
      
      # 转换数据格式以匹配前端期望的结构
      processedData = {
        run_id: staticData.run_id,
        status: "queued",
        conclusion: null,
        run_progress_pct: 0,
        total_duration: totalDuration,
        # 修改这里：使用正确的 GitHub Actions URL 格式
        run_html_url: "https://github.com/atmisboru/pytest-github-actions-example/actions/runs/#{staticData.run_id}",
        branch: vm.form.ref || "master",
        jobs: [],
        start_time: new Date().toISOString(),
        inputs: vm.form.inputs || "{}"
      }
      
      # 处理每个job
      staticData.jobs.forEach (job, jobIndex) ->
        processedJob = {
          job_id: "job_#{jobIndex}",
          job_name: job.job_name,
          status: "queued",
          job_progress_pct: 0,
          total_duration: job.total_duration,
          elapsed_time: 0,
          current_step_index: -1,
          completed_steps: 0,
          total_steps: job.steps.length,
          steps: [],
          start_time: null,
          # 添加job依赖关系
          depends_on: vm.getJobDependencies(job.job_name)
        }
        
        # 处理每个step
        job.steps.forEach (step, stepIndex) ->
          processedStep = {
            name: step.name,
            status: "queued",
            conclusion: null,
            is_current: false,
            duration: step.duration,
            elapsed_time: 0,
            progress_pct: 0,
            start_time: null,
            completed_at: null
          }
          processedJob.steps.push(processedStep)
        
        processedData.jobs.push(processedJob)
      
      return processedData

    # 获取job依赖关系 - 根据新顺序调整
    vm.getJobDependencies = (jobName) ->
      switch jobName
        when "dummy" then return []  # dummy没有依赖，最先开始
        when "build (3.10)", "build (3.11)" then return ["dummy"]  # build作业依赖dummy完成
        when "integration" then return ["build (3.10)", "build (3.11)"]  # integration依赖所有build作业完成
        when "summary" then return ["integration"]  # summary依赖integration完成
        else return []

    # 检查job是否可以开始
    vm.canJobStart = (job, run) ->
      # 如果没有依赖，可以立即开始
      if !job.depends_on || job.depends_on.length == 0
        return true
      
      # 检查所有依赖的job是否已完成
      for depJobName in job.depends_on
        depJob = run.jobs.find((j) -> j.job_name == depJobName)
        if !depJob || depJob.status != "completed"
          return false
      
      return true

    # 开始模拟进度
    vm.startSimulation = (run) ->
      runId = run.run_id
      vm.runStartTimes[runId] = new Date().getTime()
      vm.runElapsedTimes[runId] = 0
      
      console.log("开始模拟运行:", runId)
      
      # 设置运行状态为进行中
      run.status = "in_progress"
      
      # 初始化所有作业为排队状态
      run.jobs.forEach (job) ->
        job.status = "queued"
        job.start_time = null
        job.current_step_index = -1
        job.completed_steps = 0
        job.job_progress_pct = 0
        
        # 初始化所有步骤
        job.steps.forEach (step) ->
          step.status = "queued"
          step.is_current = false
          step.progress_pct = 0
          step.elapsed_time = 0
          step.start_time = null
          step.completed_at = null
      
      # 延迟开始所有作业，让用户看到排队状态
      $timeout(() ->
        # 开始没有依赖的作业（dummy作业）
        run.jobs.forEach (job) ->
          if vm.canJobStart(job, run)
            job.status = "in_progress"
            job.start_time = new Date().toISOString()
            console.log("作业 #{job.job_name} 开始运行")
        
        # 开始模拟进度
        vm.simulationIntervals[runId] = $interval ->
          vm.updateProgress(run)
        , vm.POLL_INTERVAL_MS
      , 1000)

    # 更新进度
    vm.updateProgress = (run) ->
      runId = run.run_id
      currentTime = new Date().getTime()
      vm.runElapsedTimes[runId] = (currentTime - vm.runStartTimes[runId]) / 1000
      
      # 检查是否有排队中的作业可以开始
      run.jobs.forEach (job) ->
        if job.status == "queued" && vm.canJobStart(job, run)
          job.status = "in_progress"
          job.start_time = new Date().toISOString()
          console.log("作业 #{job.job_name} 开始运行")
      
      # 更新总体进度
      totalProgress = 0
      completedJobs = 0
      
      run.jobs.forEach (job, jobIndex) ->
        jobProgress = vm.updateJobProgress(job, vm.runElapsedTimes[runId])
        totalProgress += jobProgress
        
        if job.status == "completed"
          completedJobs++
      
      # 计算总体进度百分比
      run.run_progress_pct = Math.min(100, Math.round(totalProgress / run.jobs.length))
      
      # 检查是否所有job都已完成
      if completedJobs == run.jobs.length
        run.status = "completed"
        run.conclusion = "success"
        vm.stopSimulation(runId)
        console.log("运行 #{runId} 所有任务已完成")

    # 更新单个job的进度
    vm.updateJobProgress = (job, elapsedTime) ->
      # 如果job还没开始，检查是否应该开始
      if job.current_step_index == -1 && job.status == "in_progress" && elapsedTime >= 1
        job.current_step_index = 0
        job.steps[0].status = "in_progress"
        job.steps[0].is_current = true
        job.steps[0].start_time = new Date().toISOString()
      
      # 只有在job已经开始后才更新进度
      if job.current_step_index >= 0 && job.status == "in_progress"
        job.elapsed_time = elapsedTime - (if job.start_time then 1 else 0)
        
        # 计算job的累计时间
        cumulativeTime = 0
        currentStepIndex = job.current_step_index
        
        # 计算已完成步骤的时间
        for i in [0...currentStepIndex]
          cumulativeTime += job.steps[i].duration
        
        # 处理当前步骤
        if currentStepIndex >= 0 && currentStepIndex < job.steps.length
          currentStep = job.steps[currentStepIndex]
          stepElapsed = job.elapsed_time - cumulativeTime
          
          if stepElapsed >= currentStep.duration
            # 步骤完成
            currentStep.status = "completed"
            currentStep.conclusion = "success"
            currentStep.is_current = false
            currentStep.progress_pct = 100
            currentStep.completed_at = new Date().toISOString()
            
            # 移动到下一个步骤
            job.current_step_index++
            job.completed_steps++
            
            if job.current_step_index < job.steps.length
              # 开始下一个步骤
              nextStep = job.steps[job.current_step_index]
              nextStep.status = "in_progress"
              nextStep.is_current = true
              nextStep.start_time = new Date().toISOString()
            else
              # 所有步骤完成
              job.status = "completed"
              job.job_progress_pct = 100
          else
            # 更新当前步骤进度
            currentStep.progress_pct = Math.min(100, Math.round((stepElapsed / currentStep.duration) * 100))
            currentStep.elapsed_time = stepElapsed
        
        # 计算job进度百分比
        if job.status == "completed"
          job.job_progress_pct = 100
        else
          completedDuration = 0
          for i in [0...job.current_step_index]
            completedDuration += job.steps[i].duration
          
          if job.current_step_index < job.steps.length
            currentStep = job.steps[job.current_step_index]
            currentProgress = Math.min(currentStep.duration, job.elapsed_time - completedDuration)
            completedDuration += currentProgress
          
          job.job_progress_pct = Math.min(100, Math.round((completedDuration / job.total_duration) * 100))
      
      return job.job_progress_pct

    # 停止模拟
    vm.stopSimulation = (runId) ->
      if vm.simulationIntervals[runId]
        $interval.cancel(vm.simulationIntervals[runId])
        vm.simulationIntervals[runId] = null
        console.log("运行 #{runId} 模拟已停止")

    # 触发运行 - 使用静态数据模拟
    vm.triggerRun = ->
      vm.isLoading = true
      vm.error = null
      console.log("触发CI/CD运行，使用静态数据模拟")

      # 模拟API调用延迟
      $timeout(() ->
        try
          # 优先使用可用的真实 run_id
          availableRealRunId = vm.getAvailableRealRunId()
          selectedData = null
          useRealId = true
          
          if availableRealRunId
            # 使用真实的 run_id
            selectedData = vm.getStaticDataByRunId(availableRealRunId)
            console.log("使用真实 run_id:", availableRealRunId)
          else
            # 真实 run_id 已用完，使用修改的 run_id
            randomIndex = Math.floor(Math.random() * vm.staticDataSets.length)
            selectedData = angular.copy(vm.staticDataSets[randomIndex])
            selectedData.run_id = vm.generateUniqueRunId()
            useRealId = false
            console.log("真实 run_id 已用完，使用修改的 run_id:", selectedData.run_id)
          
          processedData = vm.processStaticData(selectedData, useRealId)
          
          # 如果使用了真实 run_id，记录到已使用列表
          if useRealId
            vm.usedRunIds.push(selectedData.run_id)
            console.log("已记录使用的真实 run_id:", selectedData.run_id)
          
          vm.runs.unshift(processedData)
          vm.startSimulation(processedData)
          vm.isLoading = false
          console.log("模拟运行开始:", processedData)
        catch error
          vm.error = "处理静态数据失败: " + error
          vm.isLoading = false
      , 1000)

    # 触发多个运行
    vm.triggerMultipleRuns = ->
      vm.isLoading = true
      vm.error = null
      console.log("触发多个CI/CD运行")

      # 模拟API调用延迟
      $timeout(() ->
        try
          # 获取所有可用的真实 run_id
          availableRealRunIds = vm.staticDataSets
            .map((data) -> data.run_id)
            .filter((runId) -> vm.usedRunIds.indexOf(runId) == -1)
          
          console.log("可用的真实 run_id:", availableRealRunIds)
          
          # 先使用所有可用的真实 run_id
          availableRealRunIds.forEach (runId) ->
            staticData = vm.getStaticDataByRunId(runId)
            if staticData
              processedData = vm.processStaticData(staticData, true)
              vm.runs.unshift(processedData)
              vm.startSimulation(processedData)
              vm.usedRunIds.push(runId)
              console.log("使用真实 run_id:", runId)
          
          # 如果还需要更多运行，使用修改的 run_id
          remainingRuns = vm.staticDataSets.length - availableRealRunIds.length
          if remainingRuns > 0
            for i in [0...remainingRuns]
              randomIndex = Math.floor(Math.random() * vm.staticDataSets.length)
              selectedData = angular.copy(vm.staticDataSets[randomIndex])
              selectedData.run_id = vm.generateUniqueRunId()
              processedData = vm.processStaticData(selectedData, false)
              vm.runs.unshift(processedData)
              vm.startSimulation(processedData)
              console.log("使用修改的 run_id:", selectedData.run_id)
          
          vm.isLoading = false
          console.log("多个模拟运行开始，已使用的真实 run_id:", vm.usedRunIds)
        catch error
          vm.error = "处理静态数据失败: " + error
          vm.isLoading = false
      , 1000)

    # 重置所有任务
    vm.reset = ->
      # 停止所有模拟
      for runId, interval of vm.simulationIntervals
        $interval.cancel(interval)
      vm.simulationIntervals = {}
      vm.runs = []
      vm.error = null
      vm.isLoading = false
      vm.runElapsedTimes = {}
      vm.runStartTimes = {}
      # 注意：这里不重置 usedRunIds，这样已使用的真实 run_id 不会被重新使用
      console.log("所有任务已重置，已使用的真实 run_id 保持:", vm.usedRunIds)

    # 删除单个运行
    vm.removeRun = (run) ->
      runId = run.run_id
      vm.stopSimulation(runId)
      vm.runs = vm.runs.filter (r) -> r.run_id != runId
      # 注意：这里不从 usedRunIds 中移除，这样已使用的真实 run_id 不会被重新使用
      console.log("运行 #{runId} 已删除，已使用的真实 run_id 保持:", vm.usedRunIds)

    # 手动刷新
    vm.manualRefresh = ->
      console.log("手动刷新数据")

    # 清除错误
    vm.clearError = ->
      vm.error = null

    # === 工具方法 ===

    # 获取作业卡片类
    vm.getJobCardClass = (job) ->
      switch job.status
        when 'queued' then return 'cicd-job-card-queued'
        when 'in_progress' then return 'cicd-job-card-in-progress'
        when 'completed' then return 'cicd-job-card-completed'
        else return ''

    # 获取步骤类
    vm.getStepClass = (step) ->
      classes = []
      if step.is_current then classes.push('cicd-step-item-current')
      classes.push('cicd-step-' + step.status)
      if step.conclusion then classes.push('cicd-step-' + step.conclusion)
      return classes.join(' ')

    # 获取状态类
    vm.getStatusClass = (run) ->
      return unless run
      status = run.status
      conclusion = run.conclusion

      if status == 'completed'
        switch conclusion
          when 'success' then return 'cicd-status-success'
          when 'failure' then return 'cicd-status-failure'
          when 'cancelled' then return 'cicd-status-cancelled'
          else return 'cicd-status-completed'
      else
        switch status
          when 'queued' then return 'cicd-status-queued'
          when 'in_progress' then return 'cicd-status-in-progress'
          else return 'cicd-status-unknown'

    # 获取作业状态类
    vm.getJobStatusClass = (job) ->
      return unless job
      status = job.status
      
      switch status
        when 'queued' then return 'cicd-status-queued'
        when 'in_progress' then return 'cicd-status-in-progress'
        when 'completed' then return 'cicd-status-completed'
        else return 'cicd-status-unknown'

    # 获取步骤状态类
    vm.getStepStatusClass = (step) ->
      return unless step
      status = step.status
      
      switch status
        when 'queued' then return 'cicd-status-queued'
        when 'in_progress' then return 'cicd-status-in-progress'
        when 'completed' then return 'cicd-status-completed'
        else return 'cicd-status-unknown'

    # 获取状态文本
    vm.getStatusText = (run) ->
      return unless run
      status = run.status
      conclusion = run.conclusion

      if status == 'completed'
        switch conclusion
          when 'success' then return 'Success'
          when 'failure' then return 'Failed'
          when 'cancelled' then return 'Cancelled'
          else return 'Completed'
      else
        switch status
          when 'queued' then return 'Queued'
          when 'in_progress' then return 'In Progress'
          else return status

    # 获取作业状态文本
    vm.getJobStatusText = (job) ->
      return unless job
      status = job.status
      
      switch status
        when 'queued' then return 'Queued'
        when 'in_progress' then return 'In Progress'
        when 'completed' then return 'Completed'
        else return status

    # 获取步骤状态文本
    vm.getStepStatusText = (step) ->
      return unless step
      status = step.status
      
      switch status
        when 'queued' then return 'Queued'
        when 'in_progress' then return 'In Progress'
        when 'completed' then return 'Completed'
        else return status

    # 获取步骤持续时间
    vm.getStepDuration = (step) ->
      if step.duration?
        if step.elapsed_time > 0
          return step.elapsed_time.toFixed(1) + 's / ' + step.duration + 's'
        else
          return step.duration + 's'
      return ''

    # 获取运行持续时间
    vm.getRunDuration = (run) ->
      runId = run.run_id
      if vm.runElapsedTimes[runId] > 0
        return vm.runElapsedTimes[runId].toFixed(1) + 's'
      return ''

    # 获取作业进度
    vm.getJobProgress = (job) ->
      return job.job_progress_pct || 0

    # 获取步骤进度
    vm.getStepProgress = (step) ->
      return step.progress_pct || 0

    # 获取总体进度
    vm.getOverallProgress = (run) ->
      return run?.run_progress_pct || 0

    # 生命周期管理
    $scope.$on "$destroy", ->
      for runId, interval of vm.simulationIntervals
        $interval.cancel(interval)

    return vm
])
