allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Android SDK 从 API 36 起引入了次版本号，平台包只有 `android-36.1` / `android-37.0`
// 这样的名字，不再有裸的 `android-37`。而不少 Flutter 插件的 android/build.gradle
// 里仍写着 `compileSdk = 37`，AGP 会去找不存在的 hash `android-37` 并直接失败：
//   > Failed to find target with hash string 'android-37'
//
// 这里把所有插件子工程统一压到 36（是一个真实存在的平台包）。
// :app 不动，交给 Flutter 自己的 gradle 插件处理次版本号。
val pluginCompileSdk = 36

subprojects {
    if (name == "app") return@subprojects
    afterEvaluate {
        val androidExtension = extensions.findByName("android") ?: return@afterEvaluate
        // 用反射设置，避免依赖某个具体 AGP 版本的扩展类型
        androidExtension.javaClass.methods
            .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
            ?.invoke(androidExtension, pluginCompileSdk)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
