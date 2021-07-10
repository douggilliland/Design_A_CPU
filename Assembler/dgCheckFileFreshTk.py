#!/usr/bin/env python
"""
===================
pyCheckFileFresh.py
===================

This program allows a file to be checked for freshness.
If the file was edited on the same date as this function is run then the file is considered to be fresh.

==========
Background
==========

===
API
===

"""
from __future__ import print_function

from builtins import str
from builtins import object
import os
import datetime
import time

verboseMode = False
freshFlag = True

class CheckFreshness(object):
	"""Class which checks a file to see if it is fresh
	"""
	## Returns True if the file was saved today, False otherwise
	def isFresh(self, pathToFile):
		"""
		:param pathToFile: The path/filename to check
		:returns: True if the file is fresh (saved today), False otherwise
		
		isFresh checks to see if the file was created today
		"""
		t = os.path.getmtime(pathToFile)
		fileTimeDateStamp = datetime.datetime.fromtimestamp(t)
		fileDateStamp = str(fileTimeDateStamp)
		fileDateStamp = fileDateStamp[0:fileDateStamp.find(' ')]
		currentDate = time.strftime("%Y-%m-%d")
		if fileDateStamp == currentDate:
			if verboseMode:
				print('File is fresh')
			return True
		else:
			if verboseMode:
				print('file was not fresh')
			return False
		
	def setVerboseMode(self,verboseFlag):
		"""
		:param verboseFlag: Value To set verbose Flag True False
		
		Sets the verbose flag.
		The verbose flag can be used to see into the actions 
		of this module without changing the module in debug.
		The verbose messages go to the command prompt window.
		"""
		global verboseMode
		verboseMode = verboseFlag
		if verboseMode:
			print('setVerboseMode: setting VerboseMode flag to Verbose')
		
	def setFreshCheckFlag(self,freshnessFlag):
		"""
		:param freshnessFlag: Flag that says whether or not to check freshness
		
		Sets the fresh check flag
		"""
		global freshFlag
		global verboseMode
		if verboseMode:
			print('CheckFreshness:setFreshCheckFlag: setting freshness flag', freshnessFlag)
		freshFlag = freshnessFlag
		
	def getFreshFlag(self):
		"""
		:returns: fresh flag

		"""
		global freshFlag
		global verboseMode
		if verboseMode:
			print('CheckFreshness:getFreshFlag: getting freshness flag',freshFlag)
		return freshFlag
