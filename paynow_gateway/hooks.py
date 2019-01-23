# -*- coding: utf-8 -*-
from __future__ import unicode_literals
from . import __version__ as app_version

app_name = "paynow_gateway"
app_title = "Paynow Gateway"
app_publisher = "Chris Kateera"
app_description = "Payment gateway for paynow online payments in Zimbabwe."
app_icon = "octicon octicon-file-directory"
app_color = "blue"
app_email = "support@erp.fineco.co.zw"
app_license = "MIT"

# Includes in <head>
# ------------------

# include js, css files in header of desk.html
# app_include_css = "/assets/paynow_gateway/css/paynow_gateway.css"
# app_include_js = "/assets/paynow_gateway/js/paynow_gateway.js"

# include js, css files in header of web template
# web_include_css = "/assets/paynow_gateway/css/paynow_gateway.css"
# web_include_js = "/assets/paynow_gateway/js/paynow_gateway.js"

# include js in page
# page_js = {"page" : "public/js/file.js"}

# include js in doctype views
# doctype_js = {"doctype" : "public/js/doctype.js"}
# doctype_list_js = {"doctype" : "public/js/doctype_list.js"}
# doctype_tree_js = {"doctype" : "public/js/doctype_tree.js"}
# doctype_calendar_js = {"doctype" : "public/js/doctype_calendar.js"}

# Home Pages
# ----------

# application home page (will override Website Settings)
# home_page = "login"

# website user home page (by Role)
# role_home_page = {
#	"Role": "home_page"
# }

# Website user home page (by function)
# get_website_user_home_page = "paynow_gateway.utils.get_home_page"

# Generators
# ----------

# automatically create page for each record of this doctype
# website_generators = ["Web Page"]

# Installation
# ------------

# before_install = "paynow_gateway.install.before_install"
# after_install = "paynow_gateway.install.after_install"

# Desk Notifications
# ------------------
# See frappe.core.notifications.get_notification_config

# notification_config = "paynow_gateway.notifications.get_notification_config"

# Permissions
# -----------
# Permissions evaluated in scripted ways

# permission_query_conditions = {
# 	"Event": "frappe.desk.doctype.event.event.get_permission_query_conditions",
# }
#
# has_permission = {
# 	"Event": "frappe.desk.doctype.event.event.has_permission",
# }

# Document Events
# ---------------
# Hook on document methods and events

# doc_events = {
# 	"*": {
# 		"on_update": "method",
# 		"on_cancel": "method",
# 		"on_trash": "method"
#	}
# }

# Scheduled Tasks
# ---------------

# scheduler_events = {
# 	"all": [
# 		"paynow_gateway.tasks.all"
# 	],
# 	"daily": [
# 		"paynow_gateway.tasks.daily"
# 	],
# 	"hourly": [
# 		"paynow_gateway.tasks.hourly"
# 	],
# 	"weekly": [
# 		"paynow_gateway.tasks.weekly"
# 	]
# 	"monthly": [
# 		"paynow_gateway.tasks.monthly"
# 	]
# }

# Testing
# -------

# before_tests = "paynow_gateway.install.before_tests"

# Overriding Whitelisted Methods
# ------------------------------
#
# override_whitelisted_methods = {
# 	"frappe.desk.doctype.event.event.get_events": "paynow_gateway.event.get_events"
# }

