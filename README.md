### Overview

This is a quick and dirty script to generate a static gallery from a set of images.


### Example

http://photos.hilscher.ca/2014-algonquin/


### Prerequisites

1. Ruby ( https://www.ruby-lang.org/en/downloads/ )

2. Git ( http://git-scm.com/book/en/Getting-Started-Installing-Git )

### Usage

1. Clone or download the repo

```
git clone https://github.com/blakehilscher/static-gallery-generator.git
```

2. Install depedencies

```
cd static-gallery-generator
bundle install
```

3. Copy your images into images/

4. Run the generate

```
ruby generate.rb
```

5. Upload the result to a server.


### Future

* extract the html from generate.rb and put it into source/template.haml
* add scss precompile: source/styles.scss