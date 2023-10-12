# ChatDevDIY
https://github.com/OpenBMB/ChatDev
#### `docker-compose.yml`
```bash
services:
  chatdev:
    image: sheepgreen/chatdev
    container_name: chatdev
    environment:
      - OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    command: [ "python", "run.py", "--task", "[description_of_your_idea]", "--name", "[project_name]" ]
```
#### `docker-compose up -d` until the container exited
#### `docker logs -f chatdev` to see the process
#### After that, `docker cp chatdev:/chatdev /path/to/what/you/prefer`
