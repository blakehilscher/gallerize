### Example

http://examples.hilscher.ca/static-gallery-generator/


### Overview

* generate a static gallery from a folder of images
* responsive layout
* thumbnails and fullsize are generated automatically
* does not alter existing directory


### Installation

```
gem install gallerize-cli
```


### Usage

```
$ cd folder-with-pictures
$ gallerize
$ open static-gallery/index.html
```


### Configuration

Create .gallerize.yml in the directory that contains your photos with any of these options:

| Name          | Required?     | Example Value     | Description                                                   |
| ------------- |:-------------:| -----------------:| -------------------------------------------------------------:|
| per_page      | required      | 100               | How many photos per page?                                     |
| image_types   | required      | jpg,JPG,png,PNG   | The image formats to process                                  |
| workers       | required      | 4                 | The number of processes to use when doing CPU intensive work  |
| image_width   | required      | 1200              | The fullsize image width                                      |
| image_height  | required      | 800               | The fullsize image height                                     |
| thumb_width   | required      | 1200              | The thumbnail image width                                     |
| thumb_height  | required      | 800               | The thumbnail image height                                    |
| output_name   | optional      | gallery           | Directory name where the gallery will be created              |
| tracking      | optional      | UA-0000000-2      | Enable google analytics by entering a tracking code           |


### Future

* extract the html from generate.rb and put it into source/template.haml
* add scss precompile: source/styles.scss