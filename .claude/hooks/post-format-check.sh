#!/bin/bash
# PostToolUse hook (matcher: Edit|Write)
# 每次 Claude 编辑/写入文件后触发；从 stdin JSON 取出目标文件路径并自动格式化。
# 对 .java 使用 google-java-format 就地格式化，让你亲眼看到文件被自动整形。

FILE_PATH=$(jq -r '.tool_input.file_path // empty')

# 只处理真实存在的文件
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.java)
    if command -v google-java-format >/dev/null 2>&1; then
      # google-java-format 需要 Java 21+；当前项目用 Java 17 构建，
      # 因此在调用格式化器时显式指定一个更高版本的 JDK（如 openjdk@26），互不干扰。
      GJF_JDK=/opt/homebrew/opt/openjdk@26/libexec/openjdk.jdk/Contents/Home
      if [ -d "$GJF_JDK" ]; then
        JAVA_HOME="$GJF_JDK" google-java-format --replace "$FILE_PATH"
      else
        google-java-format --replace "$FILE_PATH"
      fi
      echo "🎯 [格式化] 已用 google-java-format 整形: $FILE_PATH"
    fi
    ;;
  *.ts | *.js | *.json)
    # 前端文件预留位（阶段 3 接入 prettier 时启用）
    :
    ;;
esac

exit 0
