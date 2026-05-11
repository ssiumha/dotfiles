# frozen_string_literal: true

require "minitest/autorun"
load File.join(__dir__, "..", "stargazer")

class TestParser < Minitest::Test
  def parse(q) = Stargazer::Parser.parse(q)

  # -- mode dispatch --

  def test_mode_pascal_case
    assert_equal "infer", parse("Wallet").mode
  end

  def test_mode_lowercase_single_word
    assert_equal "infer", parse("wallet").mode
  end

  def test_mode_http_method
    assert_equal "router", parse("GET /api").mode
  end

  def test_mode_path_prefix
    assert_equal "router", parse("/users").mode
  end

  def test_mode_ast
    assert_equal "ast", parse("$foo()").mode
  end

  def test_mode_context
    assert_equal "context", parse("&wallet").mode
  end

  def test_mode_git
    assert_equal "git", parse("!").mode
  end

  def test_mode_multi_word_default
    assert_equal "default", parse("hello world").mode
  end

  # -- pipe filter --

  def test_pipe_mode_preserved
    p = parse("Wallet | client")
    assert_equal "infer", p.mode
    assert_equal "client", p.pipe_filter
  end

  def test_pipe_router
    p = parse("GET /api | health")
    assert_equal "router", p.mode
    assert_equal "health", p.pipe_filter
  end

  def test_no_pipe
    assert_nil parse("Wallet").pipe_filter
  end

  # -- query extraction --

  def test_query_path
    assert_equal "users", parse("/users").query
  end

  def test_query_get_path
    assert_equal "/api/users", parse("GET /api/users").query
  end

  def test_query_pascal
    assert_equal "Wallet", parse("Wallet").query
  end

  def test_query_lowercase
    assert_equal "oracle", parse("oracle").query
  end

  def test_empty_grep_fallback
    p = parse("")
    assert_equal "grep", p.mode
    assert_equal "", p.query
  end

  # -- edge cases --

  def test_nil_input
    p = parse(nil)
    assert_equal "grep", p.mode
    assert_equal "", p.query
  end

  def test_single_word_infer
    assert_equal "infer", parse("wallet").mode
  end

  def test_all_caps_infer
    assert_equal "infer", parse("WALLET").mode
  end

  def test_multi_word_default
    assert_equal "default", parse("Wallet Service").mode
  end

  def test_pascal_compound_infer
    assert_equal "infer", parse("WalletService").mode
  end

  def test_git_alone
    p = parse("!")
    assert_equal "git", p.mode
    assert_equal "", p.query
  end

  def test_git_query
    p = parse("! handler")
    assert_equal "git", p.mode
    assert_equal "handler", p.query
  end

  def test_git_no_space
    assert_equal "handler", parse("!handler").query
  end

  def test_git_keyword_diff
    assert_equal "git", parse("diff handler").mode
  end

  def test_git_keyword_staged
    assert_equal "git", parse("staged handler").mode
  end

  def test_git_keyword_changed
    assert_equal "git", parse("changed handler").mode
  end

  def test_removed_prefix_multi_word
    assert_equal "default", parse("Model User").mode
  end

  def test_removed_r_prefix
    assert_equal "default", parse("r:users").mode
  end

  def test_empty_pipe
    assert_nil parse("Wallet |").pipe_filter
  end

  def test_pipe_trims_leading_space
    assert_equal "client ", parse("Wallet |  client ").pipe_filter
  end

  # -- folder filter --

  def test_folder_basic
    p = parse("create @src/auth/")
    assert_equal "infer", p.mode
    assert_equal "create", p.query
    assert_equal "src/auth/", p.folder_filter
  end

  def test_folder_at_start
    p = parse("@src/ User")
    assert_equal "infer", p.mode
    assert_equal "User", p.query
    assert_equal "src/", p.folder_filter
  end

  def test_folder_with_git
    p = parse("! @vim/lua/")
    assert_equal "git", p.mode
    assert_equal "vim/lua/", p.folder_filter
  end

  def test_folder_pipe_combo
    p = parse("Wallet @src/ | auth")
    assert_equal "infer", p.mode
    assert_equal "src/", p.folder_filter
    assert_equal "auth", p.pipe_filter
  end

  def test_no_folder
    assert_nil parse("User").folder_filter
  end

  def test_at_without_slash
    assert_nil parse("create @auth").folder_filter
  end

  def test_deep_nested_folder
    assert_equal "src/auth/controllers/", parse("create @src/auth/controllers/").folder_filter
  end

  def test_multiple_at_first_wins
    p = parse("create @src/ @lib/")
    assert_equal "src/", p.folder_filter
  end

  # -- glob filter --

  def test_glob_basic
    p = parse("User *.java")
    assert_equal "infer", p.mode
    assert_equal "User", p.query
    assert_equal "*.java", p.glob_filter
  end

  def test_glob_at_start
    p = parse("*.py User")
    assert_equal "infer", p.mode
    assert_equal "*.py", p.glob_filter
  end

  def test_glob_brace
    p = parse("create *.{js,ts}")
    assert_equal "infer", p.mode
    assert_equal "*.{js,ts}", p.glob_filter
  end

  def test_glob_alone
    p = parse("*.rb")
    assert_equal "default", p.mode
    assert_equal "*.rb", p.glob_filter
  end

  def test_no_glob
    assert_nil parse("m:User").glob_filter
  end

  def test_glob_folder_pipe_combo
    p = parse("Wallet *.ts @src/ | auth")
    assert_equal "*.ts", p.glob_filter
    assert_equal "src/", p.folder_filter
    assert_equal "auth", p.pipe_filter
  end

  def test_glob_git
    p = parse("! handler *.py")
    assert_equal "git", p.mode
    assert_equal "*.py", p.glob_filter
  end

  # -- git mode pipe --

  def test_git_pipe
    p = parse("! handler | auth")
    assert_equal "git", p.mode
    assert_equal "handler", p.query
    assert_equal "auth", p.pipe_filter
  end

  # -- folder exclude --

  def test_folder_exclude
    p = parse("create @!test/")
    assert_equal "infer", p.mode
    assert_equal "create", p.query
    assert_equal "test/", p.folder_filter
    assert_equal true, p.folder_exclude
  end

  def test_folder_exclude_deep
    p = parse("Wallet @!src/test/")
    assert_equal "src/test/", p.folder_filter
    assert_equal true, p.folder_exclude
  end

  def test_folder_include_no_exclude
    p = parse("create @src/")
    assert_equal "src/", p.folder_filter
    assert_nil p.folder_exclude
  end

  # -- pipe exclude --

  def test_pipe_exclude
    p = parse("Wallet | !Test")
    assert_equal "infer", p.mode
    assert_equal "Test", p.pipe_filter
    assert_equal true, p.pipe_exclude
  end

  def test_pipe_include_no_exclude
    p = parse("Wallet | client")
    assert_equal "client", p.pipe_filter
    assert_nil p.pipe_exclude
  end

  def test_combo_exclude
    p = parse("Wallet @!test/ | !Mock")
    assert_equal "test/", p.folder_filter
    assert_equal true, p.folder_exclude
    assert_equal "Mock", p.pipe_filter
    assert_equal true, p.pipe_exclude
  end

  def test_empty_exclude
    assert_nil parse("Wallet | !").pipe_filter
    assert_nil parse("Wallet | !").pipe_exclude
  end

  # -- special characters --

  def test_dotted_query
    p = parse("foo.bar")
    assert_equal "default", p.mode  # contains dot, not single \w+
    assert_equal "foo.bar", p.query
  end

  def test_hyphenated_query
    p = parse("foo-bar")
    assert_equal "default", p.mode  # hyphen, not single \w+
    assert_equal "foo-bar", p.query
  end

  def test_underscore_query
    p = parse("foo_bar")
    assert_equal "infer", p.mode  # \w includes underscore
    assert_equal "foo_bar", p.query
  end

  def test_whitespace_only
    p = parse("   ")
    assert_equal "default", p.mode  # non-empty string → default fallback
  end

  # -- all filters combined --

  def test_get_alone_is_infer
    assert_equal "infer", parse("GET").mode  # single word, no path
  end

  def test_get_no_slash_is_default
    assert_equal "default", parse("GET something").mode  # no / prefix
  end

  def test_git_empty_query_with_pipe
    p = parse("! | auth")
    assert_equal "git", p.mode
    assert_equal "", p.query
    assert_equal "auth", p.pipe_filter
  end

  def test_number_is_infer
    assert_equal "infer", parse("404").mode
  end

  def test_dollar_alone_not_ast
    assert_equal "default", parse("$").mode  # $ alone: no meaningful ast pattern
  end

  def test_slash_alone_is_default
    assert_equal "default", parse("/").mode  # no \w after /
  end

  def test_colon_in_query
    assert_equal "default", parse("foo:bar").mode
  end

  def test_multiple_globs_first_wins
    p = parse("*.java *.py Oracle")
    assert_equal "*.java", p.glob_filter  # first glob extracted
  end

  def test_all_filters_git
    p = parse("! handler *.py @src/ | auth")
    assert_equal "git", p.mode
    assert_equal "handler", p.query
    assert_equal "*.py", p.glob_filter
    assert_equal "src/", p.folder_filter
    assert_equal "auth", p.pipe_filter
  end

  def test_all_filters_with_exclude
    p = parse("Oracle *.ts @!test/ | !Mock")
    assert_equal "infer", p.mode
    assert_equal "Oracle", p.query
    assert_equal "*.ts", p.glob_filter
    assert_equal "test/", p.folder_filter
    assert_equal true, p.folder_exclude
    assert_equal "Mock", p.pipe_filter
    assert_equal true, p.pipe_exclude
  end
end

class TestRank < Minitest::Test
  FIXTURE_DIR = File.join(__dir__, "fixtures")
  PATTERNS = [
    { pattern: '(class|interface) \w*{q}' },
    { pattern: '@(entity|table)' },
  ]

  def compiled(patterns = PATTERNS, query: "wallet")
    Stargazer::Rank.compile_patterns(patterns, query:)
  end

  def classify(lines, patterns = PATTERNS, query: "wallet")
    Stargazer::Rank.classify(lines, compiled(patterns, query:))
  end

  # -- compile --

  def test_compile_interpolates_query
    c = compiled(query: "wallet")
    assert c[0][0].match?("class Wallet"), "first pattern matches with query"
  end

  def test_compile_no_query
    c = Stargazer::Rank.compile_patterns([{ pattern: '@service' }])
    assert c[0][0].match?("@Service"), "case insensitive match"
  end

  # -- classify + dedup --

  def test_actual_sort
    lines = File.readlines(File.join(FIXTURE_DIR, "rg_infer_wallet.txt"), chomp: true)
    buckets = classify(lines)

    total = buckets.sum(&:size)
    assert_equal 7, total  # 8 input - 1 duplicate
    assert_match(/class Wallet extends/, buckets[0][0])
    assert_match(/class WalletsClient/, buckets[0][1])
  end

  def test_dedup
    lines = ["foo.java:10:1:class Foo", "foo.java:10:1:class Foo", "bar.java:5:1:class Bar"]
    buckets = classify(lines, [{ pattern: "class" }])
    assert_equal 2, buckets.sum(&:size)
  end

  def test_multi_pattern_first_wins
    patterns = [{ pattern: "class" }, { pattern: "@entity" }]
    lines = ["a.java:1:1:@Entity class Foo", "b.java:2:1:@Entity", "c.java:3:1:other line"]
    c = Stargazer::Rank.compile_patterns(patterns)
    buckets = Stargazer::Rank.classify(lines, c)
    assert_match(/@Entity class Foo/, buckets[0][0])   # first pattern wins (class)
    assert_match(/@Entity/, buckets[1][0])              # second pattern
    assert_match(/other/, buckets[2][0])                # fallback
  end

  # -- format: grouped --

  def test_grouped_headers
    lines = File.readlines(File.join(FIXTURE_DIR, "rg_infer_oracle.txt"), chomp: true)
    patterns = Stargazer::INFER_RANK
    c = Stargazer::Rank.compile_patterns(patterns, query: "oracle")
    buckets = Stargazer::Rank.classify(lines, c)
    result = Stargazer::Rank.format(buckets, c)

    headers = result.filter_map { |l| l[/── (.+) ──/, 1] }
    assert headers.size >= 3, "at least 3 group headers"
    assert_equal "define", headers[0]
  end

  def test_grouped_empty_suppressed
    lines = ["a.java:1:1:class Oracle", "b.java:2:1:oracleService.call()"]
    patterns = [
      { pattern: 'class [a-zA-Z]*{q}', header: "define" },
      { pattern: '@entity', header: "schema" },
    ]
    c = Stargazer::Rank.compile_patterns(patterns, query: "oracle")
    buckets = Stargazer::Rank.classify(lines, c)
    result = Stargazer::Rank.format(buckets, c)

    assert result.none? { |l| l.include?("── schema ──") }, "empty schema: no header"
  end

  def test_filter_bucket_single
    lines = File.readlines(File.join(FIXTURE_DIR, "rg_infer_oracle.txt"), chomp: true)
    patterns = Stargazer::INFER_RANK
    c = Stargazer::Rank.compile_patterns(patterns, query: "oracle")
    buckets = Stargazer::Rank.classify(lines, c)
    # define is index 2 (0-based) = filter_bucket 3 (generated=1, page=2, define=3)
    result = Stargazer::Rank.format(buckets, c, filter_bucket: 3)

    # status line + define lines only
    assert result.size > 1
    result[1..].each { |l| assert_match(/class/i, l, "only define lines") }
  end

  def test_filter_bucket_fallback
    lines = ["a.java:1:1:class Oracle", "b.java:2:1:use oracle somewhere", "c.java:3:1:oracle.call()"]
    patterns = [{ pattern: 'class [a-zA-Z]*{q}', header: "define" }]
    c = Stargazer::Rank.compile_patterns(patterns, query: "oracle")
    buckets = Stargazer::Rank.classify(lines, c)
    result = Stargazer::Rank.format(buckets, c, filter_bucket: 2)

    # status + 2 reference lines
    assert_equal 3, result.size
    refute_match(/class Oracle/, result[1])
  end

  def test_reference_cap
    lines = (1..25).map { |i| "ref#{i}.java:#{i}:1:use oracle" }
    patterns = [{ pattern: "class", header: "define" }]
    c = Stargazer::Rank.compile_patterns(patterns, query: "oracle")
    buckets = Stargazer::Rank.classify(lines, c)
    result = Stargazer::Rank.format(buckets, c)

    # status + reference header + 20 lines + "more" = 23
    assert_equal 23, result.size
    assert_match(/more/, result.last)
  end

  # -- generated group priority --

  def test_generated_before_define
    lines = [
      "src/generated/api/model/ltvPolicy.ts:8:8:export interface LtvPolicy {",
      "src/app/pawn/settings/ltv/page.tsx:16:1:interface LtvPolicy {",
      "src/model/LtvPolicy.ts:5:1:export interface LtvPolicy {",
    ]
    compiled = Stargazer::Rank.compile_patterns(Stargazer::INFER_RANK, query: "ltv")
    buckets = Stargazer::Rank.classify(lines, compiled)

    # generated group (index 0) should catch generated/ paths
    assert_equal 1, buckets[0].size, "generated group: 1 line"
    assert_match(/generated/, buckets[0][0])

    # page group (index 1) should catch page files before define
    assert_equal 1, buckets[1].size, "page group: 1 line"
    assert_match(/page\.tsx/, buckets[1][0])

    # define group (index 2) should catch non-generated, non-page definitions
    assert_equal 1, buckets[2].size, "define group: 1 line (non-generated)"
    assert_match(/model\/LtvPolicy/, buckets[2][0])
  end

  def test_generated_with_filter_bucket
    lines = [
      "src/generated/api/admin.ts:10:1:export type Foo = {",
      "src/model/Foo.ts:5:1:export interface Foo {",
    ]
    compiled = Stargazer::Rank.compile_patterns(Stargazer::INFER_RANK, query: "foo")
    buckets = Stargazer::Rank.classify(lines, compiled)

    # filter_bucket=1 (generated) → only generated lines
    result = Stargazer::Rank.format(buckets, compiled, filter_bucket: 1)
    assert result[1..].all? { |l| l.include?("generated") }, "filter generated only"

    # filter_bucket=2 (define) → only non-generated definitions
    result = Stargazer::Rank.format(buckets, compiled, filter_bucket: 2)
    assert result[1..].none? { |l| l.include?("generated") }, "filter define excludes generated"
  end

  # -- edge cases --

  def test_empty_input
    compiled = Stargazer::Rank.compile_patterns(Stargazer::INFER_RANK, query: "foo")
    buckets = Stargazer::Rank.classify([], compiled)
    result = Stargazer::Rank.format(buckets, compiled)
    # status line only, no headers for empty groups
    assert_equal 1, result.size
  end

  def test_single_line
    compiled = Stargazer::Rank.compile_patterns(Stargazer::INFER_RANK, query: "foo")
    buckets = Stargazer::Rank.classify(["src/Foo.java:1:1:class Foo {"], compiled)
    result = Stargazer::Rank.format(buckets, compiled)
    # status + define header + 1 line = 3
    assert_equal 3, result.size
  end

  def test_all_same_group
    lines = (1..5).map { |i| "src/Foo#{i}.java:#{i}:1:class Foo#{i}" }
    compiled = Stargazer::Rank.compile_patterns([{ pattern: "class", header: "define" }], query: "foo")
    buckets = Stargazer::Rank.classify(lines, compiled)
    result = Stargazer::Rank.format(buckets, compiled)
    # status + define header + 5 lines = 7
    assert_equal 7, result.size
  end

  # -- nested path patterns --

  def test_generated_page_goes_to_generated
    # page.tsx inside generated/ → generated wins (path before filename)
    lines = ["src/generated/app/page.tsx:1:1:export default function Page()"]
    compiled = Stargazer::Rank.compile_patterns(Stargazer::INFER_RANK, query: "page")
    buckets = Stargazer::Rank.classify(lines, compiled)
    assert_equal 1, buckets[0].size, "generated/ path wins over page pattern"
  end

  def test_all_groups_empty_except_reference
    lines = ["a.java:1:1:some random usage"]
    compiled = Stargazer::Rank.compile_patterns(Stargazer::INFER_RANK, query: "foo")
    buckets = Stargazer::Rank.classify(lines, compiled)
    result = Stargazer::Rank.format(buckets, compiled)
    headers = result.filter_map { |l| l[/── (.+) ──/, 1] }
    assert_equal ["reference"], headers
  end

  # -- colorize --

  def test_colorize
    line = "src/main.java:10:1:class Foo"
    colored = Stargazer::Rank.colorize_line(line, true)
    assert_match(/\033\[36m/, colored, "cyan for filename")
    assert_match(/\033\[33m/, colored, "yellow for line number")
  end

  def test_no_colorize
    line = "src/main.java:10:1:class Foo"
    assert_equal line, Stargazer::Rank.colorize_line(line, false)
  end
end

class TestDispatcher < Minitest::Test
  MOCK_CTX = { root: "/tmp/test", preset_name: "test", preset: {}, has_sg: false }.freeze
  MOCK_CTX_SG = { root: "/tmp/test", preset_name: "test", preset: {}, has_sg: true }.freeze

  def parse(q) = Stargazer::Parser.parse(q)
  def dispatch(parsed, ctx = MOCK_CTX, **opts) = Stargazer::Dispatcher.dispatch(parsed, ctx, **opts)

  # -- infer grouped --

  def test_infer_cmd
    cmd = dispatch(parse("Wallet"))
    refute_nil cmd
    assert_match(/rg/, cmd)
    assert_match(/Wallet/, cmd)
  end

  def test_pipe_filter_in_cmd
    cmd = dispatch(parse("Wallet | client"))
    assert_match(/grep.*client/, cmd)
  end

  def test_nil_dispatch
    assert_nil dispatch(nil)
  end

  # -- ast --

  def test_ast_sg
    p = parse("$foo()")
    assert_equal "ast", p.mode
    cmd = dispatch(p, MOCK_CTX_SG)
    assert_match(/sg run/, cmd)
  end

  def test_ast_no_sg
    cmd = dispatch(parse("$foo()"))
    assert_match(/not found/, cmd)
  end

  # -- folder filter --

  def test_folder_filter_infer
    cmd = dispatch(parse("create @src/auth/"))
    refute_nil cmd
    assert_match(/rg/, cmd)
    assert_match(/create/, cmd)
    assert_match(/grep.*src\/auth\//, cmd)
  end

  def test_folder_filter_ordering
    cmd = dispatch(parse("Wallet @src/ | client"))
    assert_match(/grep.*src\/.*grep.*client/m, cmd)
  end

  def test_folder_filter_git
    cmd = dispatch(parse("! handler @vim/"))
    assert_match(/git diff/, cmd)
    assert_match(/grep.*vim\//, cmd)
  end

  def test_folder_filter_default
    cmd = dispatch(parse("User domain @src/domain/"))
    assert_match(/User/, cmd)
    assert_match(/grep.*src\/domain\//, cmd)
  end

  # -- context --

  def test_context_without_domain
    cmd = dispatch(parse("&"), MOCK_CTX, context_file: "")
    assert_match(/echo/, cmd)
  end

  def test_context_with_query
    cmd = dispatch(parse("& handler"), MOCK_CTX, context_file: "/project/src/auth/controller.lua")
    assert_match(/auth/, cmd)
    assert_match(/handler/, cmd)
  end

  def test_context_fallback_pattern
    cmd = dispatch(parse("&"), MOCK_CTX, context_file: "/project/src/auth/controller.lua")
    assert_match(/auth/, cmd)
    assert_match(/class/, cmd)
    assert_match(/interface/, cmd)
  end

  # -- router --

  def test_router_get_generic
    cmd = dispatch(parse("GET /api/users"))
    assert_match(/rg/, cmd)
    assert_match(/get/, cmd)
    assert_match(/\/api\/users/, cmd)
  end

  def test_router_path_with_preset
    ctx = {
      root: "/tmp/test", preset_name: "nextjs", has_sg: false,
      preset: { router: [
        Stargazer::Presets::PresetEntry.new(glob: "app/**/route.{js,ts}", pattern: 'export.*(GET|POST|PUT|DELETE|PATCH)'),
        Stargazer::Presets::PresetEntry.new(glob: "app/**/page.{js,jsx,ts,tsx}", pattern: "export default"),
      ]},
      merged_router: [
        Stargazer::Presets::PresetEntry.new(glob: "app/**/route.{js,ts}", pattern: 'export.*(GET|POST|PUT|DELETE|PATCH)'),
        Stargazer::Presets::PresetEntry.new(glob: "**/*.java", pattern: '@(Get|Post|Put|Delete|Patch|Request)Mapping'),
      ],
    }
    cmd = dispatch(parse("/audit-logs"), ctx)
    refute_nil cmd
    assert_match(/audit-logs/, cmd)
  end

  def test_router_method_path_with_preset
    ctx = {
      root: "/tmp/test", preset_name: "nextjs", has_sg: false,
      preset: { router: [
        Stargazer::Presets::PresetEntry.new(glob: "app/**/route.{js,ts}", pattern: 'export.*(GET|POST|PUT|DELETE|PATCH)'),
      ]},
    }
    cmd = dispatch(parse("GET /api/users"), ctx)
    refute_nil cmd
    assert_match(/grep.*GET/i, cmd)
  end

  # -- git --

  def test_git_status
    cmd = dispatch(parse("!"))
    assert_match(/git status/, cmd)
    assert_match(/porcelain/, cmd)
  end

  def test_git_query
    cmd = dispatch(parse("! handler"))
    assert_match(/git diff/, cmd)
    assert_match(/rg/, cmd)
    assert_match(/handler/, cmd)
  end

  def test_git_keywords
    %w[diff staged changed].each do |kw|
      cmd = dispatch(parse("#{kw} handler"))
      refute_nil cmd, "#{kw}: cmd generated"
      assert_match(/git diff/, cmd, "#{kw}: triggers git mode")
      assert_match(/handler/, cmd, "#{kw}: query passed through")
    end
  end

  def test_git_pipe
    cmd = dispatch(parse("! handler | auth"))
    assert_match(/grep.*auth/, cmd)
  end

  # -- excludes --

  def test_folder_exclude
    cmd = dispatch(parse("Wallet @!test/"))
    assert_match(/grep -v.*test\//, cmd)
  end

  def test_pipe_exclude
    cmd = dispatch(parse("create | !Test"))
    assert_match(/grep -v -i.*Test/, cmd)
  end

  def test_include_no_v_flag
    cmd1 = dispatch(parse("create @src/auth/"))
    refute_match(/grep -v/, cmd1)

    cmd2 = dispatch(parse("Wallet | client"))
    refute_match(/grep -v/, cmd2)
  end

  def test_combo_exclude
    cmd = dispatch(parse("Wallet @!test/ | !Mock"))
    assert_match(/grep -v.*test\//, cmd)
    assert_match(/grep -v -i.*Mock/, cmd)
  end

  # -- glob filter --

  def test_glob_java
    cmd = dispatch(parse("create *.java"))
    assert_match(/grep.*-E.*\.java:/, cmd)
  end

  def test_glob_brace
    cmd = dispatch(parse("create *.{js,ts}"))
    assert_match(/grep.*-E/, cmd)
    assert_match(/js/, cmd)
    assert_match(/ts/, cmd)
  end

  def test_glob_ordering
    cmd = dispatch(parse("Wallet *.ts @src/ | client"))
    assert_match(/grep.*src\/.*grep.*\.ts.*grep.*client/m, cmd)
  end

  def test_glob_alone
    cmd = dispatch(parse("*.rb"))
    assert_match(/grep.*-E.*\.rb:/, cmd)
  end

  # -- non-grouped --

  def test_default_no_group_headers
    cmd = dispatch(parse("m:User"))  # falls to default (removed prefix)
    refute_nil cmd
    refute_match(/define/, cmd)
  end

  # -- infer grouped glob filter ordering --

  def test_infer_glob_in_cmd
    cmd = dispatch(parse("Oracle *.java"))
    assert_match(/grep.*\.java/, cmd)
  end

  # -- infer grouped with filter_bucket --

  # -- router preset: Spring monorepo cross-framework --

  def test_router_path_spring_monorepo
    ctx = {
      root: "/tmp/test", preset_name: "spring", has_sg: false,
      preset: { router: [
        Stargazer::Presets::PresetEntry.new(glob: "**/*.java", pattern: '@(Get|Post|Put|Delete|Patch|Request)Mapping'),
      ]},
      merged_router: [
        Stargazer::Presets::PresetEntry.new(glob: "**/*.java", pattern: '@(Get|Post|Put|Delete|Patch|Request)Mapping'),
        Stargazer::Presets::PresetEntry.new(glob: "app/**/page.{js,jsx,ts,tsx}", pattern: "export default"),
      ],
    }
    cmd = dispatch(parse("/audit-logs"), ctx)
    refute_nil cmd
    assert_match(/Mapping/, cmd, "preset rg present")
    assert_match(/page/, cmd, "merged fallback includes page glob")
    assert_match(/audit-logs/, cmd, "path filter applied")
  end

  # -- infer config search --

  def test_infer_config_search
    cmd = dispatch(parse("Oracle"))
    assert_match(/\.yml/, cmd, "config: yml glob present")
    assert_match(/\.json/, cmd, "config: json glob present")
    assert_match(/\.toml/, cmd, "config: toml glob present")
  end

  # -- infer structural search --

  def test_infer_structural_search
    cmd = dispatch(parse("Oracle"))
    assert_match(/class/, cmd, "structural: class in pattern")
    assert_match(/interface/, cmd, "structural: interface in pattern")
  end

  # -- default mode: no grouped rank patterns in cmd --

  def test_default_mode_cmd
    cmd = dispatch(parse("hello world"))
    refute_nil cmd
    assert_match(/rg/, cmd)
    assert_match(/hello/, cmd)
    assert_match(/function/, cmd, "symbol: function in pattern")
    assert_match(/class/, cmd, "symbol: class in pattern")
  end

  # -- git mode: all keywords produce same structure --

  def test_git_all_keywords_same_structure
    %w[diff staged changed].each do |kw|
      cmd = dispatch(parse("#{kw} handler"))
      assert_match(/git diff/, cmd, "#{kw}: sources from git diff")
      assert_match(/handler/, cmd, "#{kw}: query in command")
      assert_match(/rg/, cmd, "#{kw}: searches with rg")
    end
  end

  # -- filter ordering: folder → glob → pipe (regression) --

  def test_filter_order_regression
    cmd = dispatch(parse("Oracle *.java @src/ | auth"))
    # grep pipes should appear in order: folder, glob, pipe
    folder_pos = cmd.index("grep") # first grep = folder
    glob_pos = cmd.index("grep -E") # glob uses -E
    pipe_pos = cmd.rindex("grep") # last grep = pipe

    refute_nil folder_pos
    refute_nil glob_pos
    refute_nil pipe_pos
    assert folder_pos < glob_pos, "folder before glob"
    assert glob_pos < pipe_pos, "glob before pipe"
  end

  # -- dispatcher: unknown mode --

  def test_unknown_mode
    # manually create a result with unknown mode
    parsed = Stargazer::Result.new(
      mode: "nonexistent", query: "test", method: nil, is_path: nil,
      pipe_filter: nil, pipe_exclude: nil, glob_filter: nil,
      folder_filter: nil, folder_exclude: nil
    )
    assert_nil dispatch(parsed)
  end

  def test_infer_config_search
    cmd = dispatch(parse("Oracle"))
    assert_match(/\.yml/, cmd)
    assert_match(/\.json/, cmd)
  end
end
