# KeyBook
- [KeyBook](#keybook)
  - [Assumptions](#assumptions)
  - [Approach](#approach)
    - [Tech Stack](#tech-stack)
    - [Decisions](#decisions)
  - [How to Use](#how-to-use)
    - [TLDR](#tldr)

## Assumptions
In this app, I've made a few assumptions. 
* Location isn't factored in i.e. where any booking might take place, or if any travel-time is required
* The availability view is limited to display one week at a time
* Week start is always Sunday
* We're only dealing with a NZ timezone
* Bookings can only be made for the hour, on the hour
* I've hardcoded some `User` ids etc to coincide with the `seeds.rb` file
* ...
* And I can't be the first person to use the 'KeyBook' pun

## Approach
### Tech Stack
* (Fairly) stock Rails with Stimulus, Hotwired, Tailwind and Postgres

### Decisions
* **I've used a relational model for each availability block** (rather than something like a jsonb column for a week's worth of availabilities). <br>This approach will not scale on it's own as multiple `Availabilities` _per user per day_ would crush the database really quickly, but my thinking is that an `Availability` once the datetime is in the past, is no longer relevant. As such it could be cleaned up via a scheduled job etc.
*  The `Booking` data is also mostly relevant around it's datetime, however I could envisage that it could be referenced for reporting etc so maybe either partitioning the table or iceboxing it could be done if the table starts getting too large.
* **No authentication** - would be _Devise_ 
* **No authorization/roles** (something like _Cancancan_ etc) - just added an enum `role` for each user at the mo.
* **No user registration** - just added data via `seeds.db`
* Times are all stored in `utc` (because they should be)
* I haven't removed all the stock Rails kruft
* I haven't built the ability to edit/remove existing `Availability` windows as this is really just a POC

## How to Use
There's a bit of hardcoded logic see [assumptions](#assumptions)

**NB I've created the basic Rails app in the `main` branch. I've separated the code into separate branches/PRs to make it easier to read.**

**The `availabilities` branch and [PR](https://github.com/daisho-wakazashi/keybook/pull/2) contains the initial Availabilities functionality**

**The `bookings` branch and [PR](https://github.com/daisho-wakazashi/keybook/pull/3) contains the initial Bookings functionality (includes allowing the booking to be seen on the Availability view)**

***Also, I haven't filled out the PRs as I normally would because, POC- but rest assured, in prod I'd be referencing a requirements doc, description, notes on testing etc***

I do like including things like Mermaid charts in the the documentation but there wasn't really much need to do so here.

Also, I coincidentally saw [a RubyLLM example that included booking a meeting](https://github.com/crmne/ruby_llm/releases/tag/1.9.0) which I thought was something appropriate too. 

### TLDR
1. Make sure you've got an up-to-date Rails 8.1 installation with Postgres locally
2. Pull the code down
3. Set up the database (`db:create` & `db:migrate` etc)
4. Run `db:seed`
5. Start the server (`rails server`)
6. Setting `Availabilities` can be done via [the property manager's calendar page](http://localhost:3000/property_managers/calendar)
7. Making a `Booking` can be done via the [booking page](http://localhost:3000/tenants/bookings/3)