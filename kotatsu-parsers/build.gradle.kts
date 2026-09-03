import tasks.ReportGenerateTask
import java.util.Properties

plugins {
    `java-library`
    `maven-publish`
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.ksp)
}

group = "org.koitharu"
version = "1.0"

val localConfig = Properties().apply {
    listOf(rootProject.file("local.properties"), rootProject.file("../local.properties"))
        .firstOrNull { it.isFile }
        ?.inputStream()
        ?.use(::load)
}
fun parserSecret(propertyName: String, environmentName: String): String =
	localConfig.getProperty(propertyName)?.takeIf(String::isNotBlank)
		?: System.getenv(environmentName).orEmpty()

val parserSecrets = emptyMap<String, String>()
fun kotlinString(value: String): String = buildString {
    value.forEach { character ->
        append(
            when (character) {
                '\\' -> "\\\\"
                '"' -> "\\\""
                '\n' -> "\\n"
                '\r' -> "\\r"
                else -> character
            },
        )
    }
}
val parserConfigDir = layout.buildDirectory.dir("generated/parser-config/kotlin")
val generateParserConfig by tasks.registering {
    inputs.properties(parserSecrets)
    outputs.dir(parserConfigDir)
    doLast {
        val output = parserConfigDir.get()
            .file("org/koitharu/kotatsu/parsers/ParserBuildConfig.kt")
            .asFile
        output.parentFile.mkdirs()
        output.writeText(buildString {
            appendLine("package org.koitharu.kotatsu.parsers")
            appendLine()
            appendLine("internal object ParserBuildConfig {")
            parserSecrets.forEach { (name, value) ->
                appendLine("    const val $name = \"${kotlinString(value)}\"")
            }
            appendLine("}")
        })
    }
}
tasks.configureEach {
    if (name.startsWith("ksp", ignoreCase = true)) dependsOn(generateParserConfig)
}

tasks.test {
    useJUnitPlatform()
}

ksp {
    arg("summaryOutputDir", "${projectDir}/.github")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    dependsOn(generateParserConfig)
    compilerOptions {
        freeCompilerArgs.addAll(
            "-opt-in=kotlin.RequiresOptIn",
            "-opt-in=kotlin.contracts.ExperimentalContracts",
            "-opt-in=kotlinx.coroutines.ExperimentalCoroutinesApi",
            "-opt-in=org.koitharu.kotatsu.parsers.InternalParsersApi",
        )
    }
}

kotlin {
    jvmToolchain(17)
    explicitApiWarning()
    sourceSets["main"].kotlin.srcDirs("build/generated/ksp/main/kotlin", parserConfigDir)
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
        }
    }
}

dependencies {
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.okhttp)
    implementation(libs.okio)
    implementation(libs.json)
    implementation(libs.androidx.collection)
    api(libs.jsoup)

    ksp(project(":kotatsu-parsers-ksp"))

    testImplementation(libs.junit.api)
    testImplementation(libs.junit.engine)
    testImplementation(libs.junit.params)
    testRuntimeOnly(libs.junit.launcher)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.quickjs)
}

tasks.register<ReportGenerateTask>("generateTestsReport")
