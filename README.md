MailIndex
=========

Got a non searchable gzipped mbox file of your mail archive? Mailindex will solve this.
It uses ElasticSearch to create an index of your mails and gives you the ability to search in there.

## Input

For the first release, there is just one input: `MBOX`.

### MBOX

Reads a mbox file and adds the not yet added mails to the index.
Usage:

```shell
bin/mailindex-mbox $index-prefix $mbox-file
```
