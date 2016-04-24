A collection of packer.io templates
===================================
[![Circle CI](https://circleci.com/gh/kampka/packer-templates.svg?style=svg)](https://circleci.com/gh/kampka/packer-templates)

This repository contains templates for building virtual machines and [Vagrant](http://www.vagrantup.com/) boxes using [Packer](http://www.packer.io/).
These templates are designed to build with the QMU/KVM virtualization software using packers QEMU builder support. Running the resulting Vagrant boxes will require the [vagrant-libvirt](https://github.com/pradels/vagrant-libvirt) plugin for Vagrant.


Overview
--------

The goal of these templates is to provide a minimal base to build upon.
Therefore, they contain little more than an a core system and an SSH server.
Beside that, these boxes provide:

 * A 64-bit linux system of the given distribution
 * 5 GB qcow2 harddrive
 * A BTRFS root file system
 * Root user access over ssh via the Vagrant public key
 * Root user password: `packer`
 * Unidirectional file and folder sync from the host to the machine
 * No vagrant user and login
 * No swap


Usage
-----

It is assumed that you already have QEMU / KVM and packer.io installed and setup on your system.
To build virtual machines, run:

    $ packer-io build -force template.json

To make use of the produced Vagrant box, it is assumed you have Vagrant and vagrant-libvirt installed and setup.
You can then run:

    $ vagrant box add box/<box-name>.box --name <box-name>
    $ vagrant init <box-name>
    $ vagrant up
