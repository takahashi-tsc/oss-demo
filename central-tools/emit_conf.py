#!/usr/bin/env python
import pika
import os
import sys

argvs = sys.argv
argc = len(argvs)

if (argc != 2):
    print 'Usage: %s <filename>' % argvs[0]
    quit()

conffilename = argvs[1]

amqphost = os.environ.get('AMQP_HOST', 'overcloud-controller-0.internalapi')

credentials=pika.PlainCredentials('guest', os.environ['AMQP_PASSWORD'])
connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=amqphost, credentials=credentials))
channel = connection.channel()

channel.exchange_declare(exchange='collectd-conf',
                         exchange_type='fanout')

if not os.path.isfile(conffilename):
    print 'Error: %s is not found' % conffilename
    quit()

filename = os.path.basename(conffilename)
filebody = open(conffilename, 'r').read()
message = filename + '/' + filebody
channel.basic_publish(exchange='collectd-conf',
                      routing_key='',
                      body=message)
print(" [x] Sent %r" % message)

connection.close()

