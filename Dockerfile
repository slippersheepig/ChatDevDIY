FROM alpine AS builder
RUN apk add --no-cache wget zip
RUN wget https://github.com/OpenBMB/ChatDev/archive/refs/tags/v1.1.1.zip && unzip v1.1.1.zip
RUN cp -r v1.1.1 /chatdev

FROM python:alpine
WORKDIR /chatdev
COPY --from=builder /chatdev .
RUN pip install --no-cache-dir -r requirements.txt
CMD [ "python", "run.py", "--task", "'1. Setup: Create a designated playing area that resembles a kitchen, with different stations for cooking, chopping, mixing, etc. You will also need various ingredients and cooking utensils. 2. Teams: Divide players into teams of 2-4 members. Each team will have a designated workstation and cooking area. 3. Tasks: Assign a list of tasks to be completed, such as chopping vegetables, stirring a pot, flipping pancakes, or assembling sandwiches. The tasks can be written on cards or displayed on a board. 4. Chaos cards: Prepare a deck of chaos cards that introduce unexpected events or challenges during gameplay, such as a burned dish, a missing ingredient, or a sudden time reduction. 5. Gameplay: Set a timer for a specific time limit (e.g., 5 minutes). Each team will simultaneously start completing tasks, following the instructions on the task cards. They must work together efficiently to complete as many tasks as possible. 6. Chaos events: At random intervals, a chaos card is drawn, and its instructions are immediately implemented in the game. This could include swapping teammates, switching tasks, or introducing additional obstacles that make completing tasks more difficult. 7. Scoring: At the end of the time limit, teams tally up the number of tasks completed successfully. The team with the highest score wins the game.'", "--name", "'cookgame'" ]
