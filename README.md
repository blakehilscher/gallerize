### Overview

Generate a static gallery from a folder of images. 

**Highlights**

* responsive layout
* thumbnails and fullsize are generated automatically
* does not alter existing directory


### Example

http://examples.hilscher.ca/static-gallery-generator/


### Usage

```
$ cd folder-with-pictures
$ gallerize
```


### Installation

* Clone or download the repo

```
git clone https://github.com/blakehilscher/static-gallery-generator.git
```

* Install depedencies

```
cd static-gallery-generator
bundle install
```

* Link bin/gallerize into your PATH

```
ln -s bin/gallerize /Users/me/bin/gallerize
```


### Configuration

* configure in config/global.yml

| Name          | Required?     | Example Value     | Description                                                   |
| ------------- |:-------------:| -----------------:| -------------------------------------------------------------:|
| tracking      | optional      | UA-0000000-2      | Enable google analytics by entering a tracking code           |
| per_page      | required      | 100               | How many photos per page?                                     |
| image_types   | required      | jpg,JPG,png,PNG   | The image formats to process                                  |
| workers       | required      | 4                 | The number of processes to use when doing CPU intensive work  |


### Future

* extract the html from generate.rb and put it into source/template.haml
* add scss precompile: source/styles.scss