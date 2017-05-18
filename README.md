### Jenkins CI/CD for Docker containers to Amazon ECR/ECS
---
An example repoistory of how I deploy Docker containers to ECS over Jenkins, that was optimized for webpack powered apps for frontend.

- Can be customized to match your project needs.

- Can be a CI/CD template for the microservices to help you ship your service quickly over a CI/CD platform.


#### Customization
---
That was an example built with a react/webpack project, but it can be cusomized easily to match your project setup.

- Search for TODOs and followup replacing to mtach the project needs.

- Depends on the project the docker files, and nginx configs might have different setup.


### Challenges with this setup
---

- There is a down-time between the `stop-task` step and `update-service` with (desired-count=1). this can be solved if there is two instances behind a loadbalancer and running the `ecs (stop-task/update-service)` one at a time.

- In case there is no more thatn one instance, then `HAProxy` might help?