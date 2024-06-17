#!/bin/bash

# 检查是否安装了 mdbtools 和 sqlite3
if ! command -v mdb-schema &> /dev/null || ! command -v sqlite3 &> /dev/null; then
    echo "请先安装 mdbtools 和 sqlite3"
    echo "使用 Homebrew 安装: brew install mdbtools sqlite"
    exit 1
fi

# 创建一个临时目录用于存放导出的 SQL 文件
TEMP_DIR="exports"
mkdir -p $TEMP_DIR

# 查找当前目录中的所有 .accdb 文件
for ACCESS_DB in *.accdb; do
    if [ -f "$ACCESS_DB" ]; then
        # 获取文件名（不包括扩展名）
        BASE_NAME=$(basename "$ACCESS_DB" .accdb)
        SQLITE_DB="$BASE_NAME.sqlite"
        
        echo "正在转换: $ACCESS_DB -> $SQLITE_DB"

        # 导出数据库模式
        mdb-schema "$ACCESS_DB" sqlite > schema.sql

        # 导出每个表的数据
        mdb-tables -1 "$ACCESS_DB" | while read -r table; do
            mdb-export -I sqlite "$ACCESS_DB" "$table" > "$TEMP_DIR/$table.sql"
        done

        # 创建 SQLite 数据库并导入模式
        sqlite3 "$SQLITE_DB" < schema.sql

        # 导入每个表的数据
        for file in $TEMP_DIR/*.sql; do
            sqlite3 "$SQLITE_DB" < "$file"
        done

        echo "转换完成: $ACCESS_DB -> $SQLITE_DB"

        # 清理临时文件
        rm -rf $TEMP_DIR/* schema.sql
    fi
done

# 删除临时目录
rmdir $TEMP_DIR

echo "所有文件转换完成"

