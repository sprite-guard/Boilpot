# Boilpot
## A simple language for simple stories

**DANGER: This is a very new thing and I haven't tested it real good.**

Boilpot is a very simple scripting language for describing
simple situations and possible ways that they can play out.
The name is a reference to two things: first to Chris Pressey's
[Samovar](https://git.catseye.tc/Samovar/), which was the main
inspiration for this project, and second to the intended use
of the language, which is to procedurally generate potboiler stories.

```ruby
require "boilpot.rb"

story = Boilpot.parse story.boil
story.seek
story.log.each_with_index do |l,i|
    puts "#{i}: #{l}"
end 
```

## The Basics

A Boilpot file defines a scenario, which consists of three things:

* Facts, which are short relational statements.
* Conditions, which are statements about facts that may or may not be true.
* Actions, which are events that are triggered by conditions.

The Boilpot parser returns a scenario as a Ruby object. The `Scenario#seek`
method causes the interpreter to search for conditions that can be satisfied,
and then triggers actions based on those conditions.

Every line in a Boilpot file that ends with a colon is a section heading, unless
the colon is escaped with a backslash. Section headings must be one of the
following keywords:

```
facts:
when:
unless:
then:
report:
```

Sections must be separated by blank lines (lines with only whitespace) and the
file must end with a blank line.

## Facts

Every Boilpot file has to start with a facts block. This starts with the word
"facts" followed by a colon, followed by any number of lines that each describe
a single fact.

The Boilpot interpreter doesn't actually understand the logical meaning of any
of these facts, their logical structure and meaning are supplied by the
conditions and actions. They can have any number of words in them, and any
grammatical structure.

```
facts:
  charles is alive
  charles has treasure
  frank is alive
  frank wants treasure
```

## When

A `when` block begins the description of a condition. It consists of a series
of statements that are structured similarly to facts, but contain variables,
which are marked 

```
when:
  :a has :b
  :c wants :b
```

The core loop of the `.seek` method is looking for valid assignments of the
variables. When it finds a set of assignments that yields a set of facts which
all hold, it causes the associated action to happen.

## Unless

The `unless` block serves as an opposite to the `when` block. If there is a
valid assignment for this section, then the action will be canceled.

```
unless:
  :a is alive
```

## Then

The `then` block begins the description of the Action. This has two parts:
a series of changes to apply to the facts, and a report to write about
the event that has happened.

Lines in a `then` block look essentially the same as lines in the `when` block,
and the variables retain their bindings. The bound value of each line in the
`then` block is added to the list of facts, unless the line is preceded by `~`,
in which case the matching fact is removed, if it exists.

```
then:
  :c has :b
  ~:a has :b
```

## Report

The report block contains a message to log indicating that a match was found
and that changes were made. All variables will be substituted with the discovered
values, and then the resulting string will be written to a log that can be
accessed with the `log` method on the `Scenario` object.

```
report:
  :c takes the :a from :b
```