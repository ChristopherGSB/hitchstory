Multiple stories played:
  preconditions:
    base.story: |
      Base story:
        given:
          random variable: some value
    example1.story: |
      Create file:
        based on: base story
        steps:
          - Create file
      Create file again:
        based on: base story
        steps:
          - Create file
    example2.story: |
      Create files:
        based on: base story
        steps:
          - Create file
    setup: |
      from hitchstory import StoryCollection, BaseEngine
      from code_that_does_things import *
      from pathquery import pathq

      class Engine(BaseEngine):
          def create_file(self, filename="step1.txt", content="example"):
              with open(filename, 'w') as handle:
                  handle.write(content)
  variations:
    Running all tests in order of name:
      preconditions:
        code: |
          results = StoryCollection(pathq(".").ext("story"), Engine()).ordered_by_name().play()
          output(results.report())
      scenario:
      - Run code
      - Output is: |
          STORY RAN SUCCESSFULLY ((( anything )))/base.story: Base story in 0.1 seconds.
          STORY RAN SUCCESSFULLY ((( anything )))/example1.story: Create file in 0.1 seconds.
          STORY RAN SUCCESSFULLY ((( anything )))/example1.story: Create file again in 0.1 seconds.
          STORY RAN SUCCESSFULLY ((( anything )))/example2.story: Create files in 0.1 seconds.

    Running all tests in a single file:
      preconditions:
        code: |
          results = StoryCollection(pathq(".").ext("story"), Engine()).in_filename("example1.story").ordered_by_name().play()
          output(results.report())
      scenario:
      - Run code
      - Output is: |
          STORY RAN SUCCESSFULLY ((( anything )))/example1.story: Create file in 0.1 seconds.
          STORY RAN SUCCESSFULLY ((( anything )))/example1.story: Create file again in 0.1 seconds.


    Using .one() on a group of stories will fail:
      preconditions:
        code: |
          StoryCollection(pathq(".").ext("story"), Engine()).one()
      scenario:
      - Raises exception: |
          More than one matching story:
          Create file (in /home/colm/.hitch/90646u/state/example1.story)
          Create files (in /home/colm/.hitch/90646u/state/example2.story)
          Create file again (in /home/colm/.hitch/90646u/state/example1.story)


Fail fast:
  preconditions:
    example1.story: |
      A Create file:
        steps:
        - Create file
      B Create file:
        steps:
        - Fail
    example2.story: |
      C Create file a third time:
        steps:
          - Create file
    setup: |
      from hitchstory import StoryCollection, BaseEngine
      from code_that_does_things import *
      from pathquery import pathq


      class Engine(BaseEngine):
          def create_file(self, filename="step1.txt", content="example"):
              with open(filename, 'w') as handle:
                  handle.write(content)

          def fail(self):
              raise Exception("Error")

  variations:
    Stop on failure is default behavior:
      preconditions:
        code: |
          results = StoryCollection(
              pathq(".").ext("story"), Engine()
          ).ordered_by_name().play()
          output(results.report())
      scenario:
      - Run code
      - Output will be:
          reference: continue-on-failure
          changeable:
          - STORY RAN SUCCESSFULLY ((( anything )))/example1.story
          - FAILURE IN ((( anything )))/example1.story
          - ((( anything )))/story.py
          - ((( anything )))/engine.py
          - ((( anything )))/examplepythoncode.py
          - STORY RAN SUCCESSFULLY ((( anything )))/example2.story


    Continue on failure:
      preconditions:
        code: |
          results = StoryCollection(
              pathq(".").ext("story"), Engine()
          ).ordered_by_name().continue_on_failure().play()
          output(results.report())
      scenario:
      - Run code
      - Output will be:
          reference: continue-on-failure
          changeable:
          - STORY RAN SUCCESSFULLY ((( anything )))/example1.story
          - FAILURE IN ((( anything )))/example1.story
          - ((( anything )))/story.py
          - ((( anything )))/engine.py
          - ((( anything )))/examplepythoncode.py
          - STORY RAN SUCCESSFULLY ((( anything )))/example2.story
