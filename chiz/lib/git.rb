module Lib
  class GitChiz < Base
    md :grep, 'git history grep', <<~MD, lang: :bash
      # 히스토리 전체 패치에서 코드 검색하기
      git log --patch -S <text>
    MD

    md :patch, 'git revision apply', <<~MD, lang: :bash
      # 같은 diff를 파일 경로만 바꿔서 적용하기
      git show 131cbb2 --patch -- . ':!**/Gemfile.lock' | perl -pe 's;src/app;src/tmp/app;g' | git apply -
    MD

    md :chmod, 'update git chmod', <<~MD, lang: :bash
      # https://git-scm.com/docs/git-update-index#Documentation/git-update-index.txt---chmod-x
      git update-index --chmod=+x /path/to/file

      # ref config
      git config core.fileMode
    MD

    md :show_revision_file, 'show specific revision file', <<~MD, lang: :bash
      # 임의의 revision 파일 확인
      git show <revision|branch|HEAD~xx>:./path/to/file/xxx.rb | bat -lruby

      # 복구시켜서 확인하기
      git restore -s <revision|branch> -- file_path
    MD

    md :fetch_file, 'checkout file specific revision', <<~MD, lang: :bash
      git checkout <REV> -- file1/to/restore file1/to/restore
    MD

    md :fetch_tag, 'fetch specific tag', <<~MD, lang: :bash
      # 전체 태그 받아오기
      git fetch --tags

      # 단일 태그 받아오기
      git fetch origin tag v1.0.0 --no-tags # shortcut
      git fetch origin 'refs/tags/1.0.0:refs/tags/1.0.0'

      # checkout
      git switch -d tags/1.0.0
    MD

    md :archive, 'get specific revision', <<~MD, lang: :bash
      for rev in 1 3 5
      do
        mkdir -p archive/$rev
        git archive --output=archive/$rev/files.tar $rev src/app
        tar xf archive/$rev/files.tar -C archive/$rev
      done
    MD
  end
end
