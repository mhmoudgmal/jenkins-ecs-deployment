node {
  ws("workspace/${env.JOB_NAME}/${env.BRANCH_NAME}") {
    try {
      // Notify slack, new build started!
      stage("BUILD STARTED") {
        slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
      }

      final String STAGING     = "staging"
      final String PRODUCTION  = "production"

      def wepackCfg
      def imageTag
      def serviceName
      def taskFamily
      def dockerFilePrefix
      def clusterName // Note that I have a cluster per environment to make it easy for each environment to configure the scalability options(ELB, ..etc)

      // FIXME: please provide the corresponding values of the environment.
      // Also, this is ok if you have a fixed deployment environments, otherwis..
      // this should be refactored to be more flexible, scalable and easy configurable,
      // and to apply the OCP, avoid opening this code later.
      if  (env.BRANCH_NAME == "staging") {
        wepackCfg         = ""
        imageTag          = ""
        serviceName       = ""
        taskFamily        = ""
        dockerFilePrefix  = STAGING
        clusterName       = ""
      } else if  (env.BRANCH_NAME == "master") {
        wepackCfg         = ""
        imageTag          = ""
        serviceName       = ""
        taskFamily        = ""
        dockerFilePrefix  = PRODUCTION
        clusterName       = ""
      }

      def remoteImageTag  = "${imageTag}-${BUILD_NUMBER}"

      def taskDefile      = "file://aws/task-definition-${remoteImageTag}.json"
      def ecRegistry      = "https://%ACCOUNT%.dkr.ecr.eu-central-1.amazonaws.com"

      /*
      / node-7.0.0 is a tag name for nodejd tool installation in Jenkins server,
      / check the Global tool configuration #NodeJSInstallation section
      / this is required to be able to access npm cli tools
      */
      def nodeHome = tool name: "node-7.0.0",
                          type: "jenkins.plugins.nodejs.tools.NodeJSInstallation"

      env.PATH = "${nodeHome}/bin:${env.PATH}"


      stage("Checkout") {
        checkout scm
      }

      stage("Project Build") {
        // TODO: specify how you would build your project
        //
        // @example ---------------------------
        // sh "rm -rf ./node_modules/*"
        // sh "npm install"
        // sh "npm install -g webpack"
        // sh "webpack --config webpack.config.${wepackCfg}.js --progress"
      }

      stage("Docker build") {
        sh "cp -r  ~/certs ."
        //  TODO: replace the ecr (repo) with the right repo name.
        sh "docker build --no-cache -t repo:${remoteImageTag} \
                                    -f ${dockerFilePrefix}.Dockerfile ."
      }

      stage("Docker push") {
        // NOTE:
        //  ecr: is a required prefix
        //  eu-central-1: is the region where the Registery located
        //  aws-ecr: is the credentials ID located in the jenkins credentials
        //
        docker.withR      (ecRegistry, "ecr:eu-central-1:aws-ecr") {
          docker.image("repo:${remoteImageTag}").push(remoteImageTag)
        }
      }

      /*
      / These steps to create new revision of the TaskDefinition, then -
      / update the servie with the new TaskDefinition revision to deploy the image
      */
      stage("Deploy") {
        // Replace BUILD_TAG placeholder in the task-definition file -
        // with the remoteImageTag (imageTag-BUILD_NUMBER)
        sh  "                                                                     \
          sed -e  's;%BUILD_TAG%;${remoteImageTag};g'                             \
                  aws/task-definition.json >                                      \
                  aws/task-definition-${remoteImageTag}.json                      \
        "

        // Get current [TaskDefinition#revision-number]
        def currTaskDef = sh (
          returnStdout: true,
          script:  "                                                              \
            aws ecs describe-task-definition  --task-definition ${taskFamily}     \
                                              | egrep 'revision'                  \
                                              | tr ',' ' '                        \
                                              | awk '{print \$2}'                 \
          "
        ).trim()

        def currentTask = sh (
          returnStdout: true,
          script:  "                                                              \
            aws ecs list-tasks  --cluster ${clusterName}                          \
                                --family ${taskFamily}                            \
                                --output text                                     \
                                | egrep 'TASKARNS'                                \
                                | awk '{print \$2}'                               \
          "
        ).trim()

        /*
        / Scale down the service
        /   Note: specifiying desired-count of a task-definition in a service -
        /   should be fine for scaling down the service, and starting a new task,
        /   but due to the limited resources (Only one VM instance) is running
        /   there will be a problem where one container is already running/VM,
        /   and using a port(80/443), then when trying to update the service -
        /   with a new task, it will complaine as the port is already being used,
        /   as long as scaling down the service/starting new task run simulatenously
        /   and it is very likely that starting task will run before the scaling down service finish
        /   so.. we need to manually stop the task via aws ecs stop-task.
        */
        if(currTaskDef) {
          sh  "                                                                   \
            aws ecs update-service  --cluster ${clusterName}                      \
                                    --service ${serviceName}                      \
                                    --task-definition ${taskFamily}:${currTaskDef}\
                                    --desired-count 0                             \
          "
        }
        if (currentTask) {
          sh "aws ecs stop-task --cluster ${clusterName} --task ${currentTask}"
        }

        // Register the new [TaskDefinition]
        sh  "                                                                     \
          aws ecs register-task-definition  --family ${taskFamily}                \
                                            --cli-input-json ${taskDefile}        \
        "

        // Get the last registered [TaskDefinition#revision]
        def taskRevision = sh (
          returnStdout: true,
          script:  "                                                              \
            aws ecs describe-task-definition  --task-definition ${taskFamily}     \
                                              | egrep 'revision'                  \
                                              | tr ',' ' '                        \
                                              | awk '{print \$2}'                 \
          "
        ).trim()

        // ECS update service to use the newly registered [TaskDefinition#revision]
        //
        sh  "                                                                     \
          aws ecs update-service  --cluster ${clusterName}                        \
                                  --service ${serviceName}                        \
                                  --task-definition ${taskFamily}:${taskRevision} \
                                  --desired-count 1                               \
        "
      }

      stage("BUILD SUCCEED") {
        slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
      }
    } catch(e) {
      slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
      throw e
    }
  }
}
