#!/bin/bash
# Initialize WebDAV test data

# Create directory structure
mkdir -p /var/webdav/test/folder1
mkdir -p /var/webdav/test/zzz_folder
mkdir -p /var/webdav/test/aaa_folder
mkdir -p /var/webdav/test/nested
mkdir -p /var/webdav/test/deep/subfolder
mkdir -p /var/webdav/test/deep/anotherfolder
mkdir -p "/var/webdav/test/한글폴더"
mkdir -p "/var/webdav/test/공백 폴더"

# Create test files
cat > /var/webdav/test/file1.txt << 'EOF'
This is test file content.
Line 2
Line 3
EOF

cat > /var/webdav/test/한글.md << 'EOF'
# 한글 문서

테스트 내용입니다.
EOF

cat > /var/webdav/test/001_file.txt << 'EOF'
Mock content for /test/001_file.txt
EOF

cat > /var/webdav/test/deep/file.txt << 'EOF'
Deep path file content
Line 2
EOF

cat > /var/webdav/test/deep/aaa.md << 'EOF'
# AAA Document
EOF

cat > /var/webdav/test/deep/zzz.txt << 'EOF'
ZZZ content
EOF

cat > /var/webdav/test/deep/subfolder/nested.txt << 'EOF'
Nested file content
EOF

# Korean folder test files
cat > "/var/webdav/test/한글폴더/test.txt" << 'EOF'
Korean folder test content
EOF

cat > "/var/webdav/test/공백 폴더/file.txt" << 'EOF'
Space folder test content
EOF

# Wikilink test data - vault structure
mkdir -p /var/webdav/vault/notes/daily
mkdir -p /var/webdav/vault/projects

cat > /var/webdav/vault/index.md << 'EOF'
# Vault Index

Links:
- [[/notes/index.md]]
- [[projects/todo.md]]
- [[korean-note]]
EOF

cat > /var/webdav/vault/notes/index.md << 'EOF'
# Notes Index

- [[../index.md]]
- [[daily/2024-01-01.md]]
- [[/projects/todo.md]]
EOF

cat > /var/webdav/vault/notes/daily/2024-01-01.md << 'EOF'
# Daily Note 2024-01-01

## Links
- Absolute: [[/notes/index.md]]
- Relative parent: [[../index.md]]
- Filename only: [[todo]]
- Korean note: [[korean-note]]
EOF

cat > /var/webdav/vault/projects/todo.md << 'EOF'
# TODO List

- [ ] Task 1
- [ ] Task 2
EOF

cat > /var/webdav/vault/korean-note.md << 'EOF'
# Korean Note

Test content for Korean note.
EOF

# Deep path vault structure (for testing /vault/nested/path scenario)
mkdir -p /var/webdav/vault/nested/path/notes
mkdir -p /var/webdav/vault/nested/path/subdir

cat > /var/webdav/vault/nested/path/index.md << 'EOF'
# Deep Vault Index

Links:
- [[/subdir/note.md]]
- [[notes/daily.md]]
EOF

cat > /var/webdav/vault/nested/path/notes/daily.md << 'EOF'
# Daily Notes

- [[/subdir/note.md]]
- [[../index.md]]
EOF

cat > /var/webdav/vault/nested/path/subdir/note.md << 'EOF'
# Subdir Note

Quick capture content.
EOF


# Set permissions
chmod -R 777 /var/webdav
