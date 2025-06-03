allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        google()
        mavenCentral()
    }
}

// 全局配置Java版本，确保Java和Kotlin任务兼容性
subprojects {
    // 配置Java工具链
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    // 配置Java编译任务
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    // 配置Kotlin编译任务
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            jvmTarget = "17"
        }
    }

    // 确保所有项目使用相同的Java版本
    afterEvaluate {
        tasks.withType<JavaCompile> {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
}


// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }
// subprojects {
//     project.evaluationDependsOn(":app")
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
