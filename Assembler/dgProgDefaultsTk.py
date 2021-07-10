#!/usr/bin/env python
"""
===================
dgProgDefaultsTk.py
===================

This method handles program defaults.

==========
Background
==========

Programs need to have certain defaults from one run to another.
This file has those functions.

Uses Python 3 and Tkinter

================
Input File Types
================

This method supports the following types of BOMs as inputs:

- DEFAULTS.csv -The defaults file

The defaults file has KEY,Value pairs in clear text

Typical use

- defaultParmsClass = HandleDefault()
- defaultParmsClass.initDefaults()
- defaultPath = defaultParmsClass.getKeyVal('DEFAULT_PATH')

====
Code
====

"""
#from __future__ import print_function

from builtins import object
import string
import csv
import os


dgProgDefaultsModuleName = 'dgProgDefaultsTk.py'
progVer = '2020-01-29'

defaultsFileNamePath = '.\\Defaults.csv'

verboseMode = False

class HandleDefault(object):
	""""Load and save defaults file
	This can be used to save stuff like the default path
	The file is a simple list with KEY, value pairs on individual lines
	"""
	def initDefaults(self):
		global defaultPath
		global defaultsFileNamePath
		global verboseMode
		defaultFilePath = os.getcwd()
		defaultsFileNamePath = defaultFilePath + '\\Defaults.csv'
		if verboseMode:
			print('initDefaults: set defaultsFileNamePath to', defaultsFileNamePath)
		if self.ifExistsDefaults() == True:
			detailParmList = self.loadDefaults()
			if verboseMode:
				print('initDefaults: loaded defaults file')
		else:
			if verboseMode:
				print('initDefaults: defaults file did not exist')
			self.createDefaults()
			if verboseMode:
				print('initDefaults: created defaults file')
			detailParmList = self.loadDefaults()
			if verboseMode:
				print('initDefaults: loaded defaults file')
		if self.getKeyVal('DEFAULT_PATH') == False:
			if verboseMode:
				print('initDefaults: There was no default path set')
			self.storeKeyValuePair('DEFAULT_PATH',defaultPath)
		return True
		
	def loadDefaults(self):
		"""
		:return: the default list of key names and key values

		Load the defaults file
		"""
		defaultFileHdl = open(defaultsFileNamePath, 'r')
		defaultListItem = csv.reader(defaultFileHdl)
		defaultList = [row for row in defaultListItem]
		# defaultList = []
		# for row in defaultListItem:
			# defaultList+=row
		return defaultList

	def getKeyVal(self, keyName):
		"""
		:param: keyName - the name of the key to look up
		:return: the value of that key, blank if there is no corresponding key
		
		Feed it a key name and it returns the corresponding key value
		"""
		global verboseMode
		if self.ifExistsDefaults() == False:
			if verboseMode:
				print('getKeyVal: had to create defaults')
			self.createDefaults()
		elif verboseMode:
			print('getKeyVal: did not have to create defaults.csv')
		defaultFileHdl = open(defaultsFileNamePath, 'r')
		defaultListItem = csv.reader(defaultFileHdl)
		for row in defaultListItem:
			if row != []:
				if row[0] == keyName:
					if verboseMode:
						print('getKeyVal: found a match for key,',keyName,'match was', row[1])
					return row[1]
		if verboseMode:
			print('getKeyVal: did not find a match for the key',keyName,'creating key')
		self.storeKeyValuePair(keyName,'.')
		return ''
	
	def storeKeyValuePair(self,keyName,valueToWrite):
		if verboseMode:
			print('storeKeyValuePair: setting key',keyName, 'to value',valueToWrite)
		if self.ifExistsDefaults() == False:
			print('storeKeyValuePair: had to create defaults')
			self.createDefaults()
		defaultFileHdl = open(defaultsFileNamePath, 'r')
		defaultListItem = csv.reader(defaultFileHdl)
		newList = []
		foundKey = False
		for item in defaultListItem:
			if verboseMode:
				print('storeKeyValuePair: item',item)
			newLine = []
			if item != []:
				if item[0] == keyName:
					newLine.append(item[0])
					newLine.append(valueToWrite)
					foundKey = True
					if verboseMode:
						print('storeKeyValuePair: found the key',item[0])
						print("storeKeyValuePair: made a new list entry with",newLine)
				else:
					newLine = item
				newList.append(newLine)
		if verboseMode:
			print("storeKeyValuePair: newList",newList)
		if not foundKey:
			if verboseMode:
				print("storeKeyValuePair: Adding new key")
			newLine = []
			newLine.append(keyName)
			newLine.append(valueToWrite)
			newList.append(newLine)
		if verboseMode:
			print("storeKeyValuePair: Storing defaults list",newList)
		self.storeDefaults(newList)
		return True
		
	def storeDefaults(self,defaultList):
		""" 
		:param: feed it the default key name and key value pairs
		:return: True if successful
		
		Store the key name and key value pair list to the defaults file
		"""
		if verboseMode:
			print('storeDefaults: storing list', defaultList)
		defaultFileHdl = open(defaultsFileNamePath, 'w', newline='')
		defaultFile = csv.writer(defaultFileHdl)
		defaultFile.writerows(defaultList)
		return True

	def createDefaults(self):
		""" 
		:return: True if successful
		
		Create the defaults file with a single pair
		"""
		defaultFileHdl = open(defaultsFileNamePath, 'w', newline='')
		defaultFile = csv.writer(defaultFileHdl)
		defaultArray = ['DEFAULT_PATH','.']
		defaultFile.writerow(defaultArray)
		return True
		
	def ifExistsDefaults(self):
		"""
		:return: True if the default file exists, false if the default file does not exist
		
		Check if the defaults file exists
		"""
		try:
			open(defaultsFileNamePath)
		except:
			return False
		return True
		
	def setVerboseMode(self,verboseFlag):
		global verboseMode
		verboseMode = verboseFlag
