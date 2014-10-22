# BEGIN { $Pegex::Parser::Debug = 1 }
use t::TestPegex;

use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;
# use XXX;

sub run {
    my $block = shift;
    my $title = $block->{title};
    my $grammar = $block->{points}{grammar};
    my $compile = $block->{points}{compile};
    my $boot_compile = fixup(yaml(bootstrap_compile($grammar)));
    is $boot_compile, $compile, "$title - Bootstrap compile is correct";
    my $pegex_compile = fixup(yaml(pegex_compile($grammar)));
    is $pegex_compile, $compile, "$title - Pegex compile is correct";
}

sub pegex_compile {
    my $grammar_text = shift;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = shift;
    Pegex::Compiler::Bootstrap->new->parse($grammar_text)->tree;
}

sub fixup {
    my $yaml = shift;
    $yaml =~ s/\A---\s\+top.*\n//;
    return $yaml;
}

sub yaml {
    return YAML::XS::Dump(shift);
}

__DATA__

plan: 22

blocks:
- title: Single Regex
  points:
    grammar: |
        a: /x/
    compile: |
        a:
          .rgx: x

- title: Single Reference
  points:
    grammar: |
        a: <b>
    compile: |
        a:
          .ref: b

- title: Single Error
  points:
    grammar: |
        a: `b`
    compile: |
        a:
          .err: b

- title: Simple All Group
  points:
    grammar: |
        a: /b/ <c>
    compile: |
        a:
          .all:
          - .rgx: b
          - .ref: c

- title: Ref Quantifier
  points:
    grammar: |
        a: <b>*
    compile: |
        a:
          +qty: '*'
          .ref: b

- title: Negative and Positive Assertion
  points:
    grammar: |
      a: !<b> =<c>
    compile: |
      a:
        .all:
        - +asr: -1
          .ref: b
        - +asr: 1
          .ref: c

- title: Skip and Wrap Marker
  points:
    grammar: |
        a: .<b> +<c>+ -<d>?
    compile: |
        a:
          .all:
          - -skip: 1
            .ref: b
          - +qty: +
            -wrap: 1
            .ref: c
          - +qty: '?'
            -pass: 1
            .ref: d

- title: List Separator
  points:
    grammar: |
        a: <b> | <c> ** /d/
    compile: |
        a:
          .any:
          - .ref: b
          - .ref: c
            .sep:
              .rgx: d

- title: List Separator
  points:
    grammar: |
        a: <b> | <c>? ** /d/
    compile: |
        a:
          .any:
          - .ref: b
          - +qty: '?'
            .ref: c
            .sep:
              .rgx: d

- title: Bracketed
  points:
    grammar: |
        a: <b> [ <c> <d> ]?
    compile: |
        a:
          .all:
          - .ref: b
          - +qty: '?'
            .all:
            - .ref: c
            - .ref: d

- title: Skip Bracketed
  points:
    grammar: |
        a: <b> .[ <c> <d> ]
    compile: |
        a:
          .all:
          - .ref: b
          - -skip: 1
            .all:
            - .ref: c
            - .ref: d
