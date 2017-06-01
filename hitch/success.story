Story success:
  preconditions:
    files:
      example.story: |
        Create files:
          scenario:
            - Create file
            - Create file: step2.txt
            - Create file:
                file name: step3.txt
                content: third step
      engine.py: |
        from hitchstory import BaseEngine
        from code_that_does_things import *


        class Engine(BaseEngine):
            def create_file(self, file_name="step1.txt", content="example"):
                with open(file_name, 'w') as handle:
                    handle.write(content)

            def on_success(self):
                reticulate_splines()

                with open("ranstory.txt", 'w') as handle:
                    handle.write(self.story.name)
  scenario:
    - Run command: |
        from hitchstory import StoryCollection
        from pathquery import pathq
        from engine import Engine

        result = StoryCollection(pathq(".").ext("story"), Engine()).named("Create files").play()
        output(result.report())
    - Output is: |
        STORY RAN SUCCESSFULLY ((( anything )))/example.story: Create files in 0.1 seconds.
    - File was created with:
        filename: step1.txt
        contents: example
    - File was created with:
        filename: step2.txt
        contents: example
    - File was created with:
        filename: step3.txt
        contents: third step
    - File was created with:
        filename: ranstory.txt
        contents: Create files
    - Splines reticulated