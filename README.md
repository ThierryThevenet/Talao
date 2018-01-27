# Talao #

## A brief on the conventions used for this project. ##
We follow the [solidity style guide](http://solidity.readthedocs.io/en/develop/style-guide.html). Complementary conventions are listed below. They will evolve with time.

### Contracts ###
Write contracts like independent services (e.g. voting contracts should not know about token contracts). This has multiple obvious advantages:
 - Team organization - starting to contribute is much easier, contracts may evolve independently...
 - Security conscious - scopes/access rights are more clearly defined, auditing code is easier.

### Comments ###
 - Write in English,
 - Use [doxygen](https://www.stack.nl/~dimitri/doxygen/manual/index.html) tags for documentation,
 - File introduction & function documentation comments should use `/* ... */` style (`/** ... */` for doxygen),
 - To make code sections explicit, write headers such as `/* EVENTS */`.
