# -*- coding: utf-8 -*-
# Copyright (c) 2018, FINECO PVT LTD and contributors
# For license information, please see license.txt

"""
# Integrating PayNow

# Paynow API Settings entered by user
PAYNOW_INIT_URL 
PAYNOW_INTEGRATION_ID
PAYNOW_INTEGRATION_KEY


### 2. Redirect for payment

Example:

	payment_details = {
		"amount": 600,
		"title": "Payment for bill : 111",
		"description": "payment via cart",
		"reference_doctype": "Payment Request",
		"reference_docname": "PR0001",
		"payer_email": "NuranVerkleij@example.com",
		"payer_name": "Nuran Verkleij",
		"order_id": "111",
		"currency": "USD",
		"payment_gateway": "Razorpay"
	}

	# redirect the user to this url
	url = controller().get_payment_url(**payment_details)


### 3. On Completion of Payment

Write a method for `on_payment_authorized` in the reference doctype

Example:

	def on_payment_authorized(payment_status):
		# your code to handle callback

##### Note:

payment_status - payment gateway will put payment status on callback.
For paypal payment status parameter is one from: [Completed, Cancelled, Failed]


More Details:
<div class="small">For details on how to get your API credentials, follow this link: <a href="https://developer.paypal.com/docs/classic/api/apiCredentials/" target="_blank">https://developer.paypal.com/docs/classic/api/apiCredentials/</a></div>

"""

from __future__ import unicode_literals
import frappe
import json
import hashlib


from six.moves.urllib import parse
from six.moves.urllib.parse import *
from six.moves.urllib.parse import quote
import six

from six.moves.urllib.request import Request
from six.moves.urllib.request import urlopen

from frappe import _
from frappe.utils import get_site_base_path
from frappe.utils import get_url, call_hook_method, cint
from frappe.model.document import Document
from frappe.integrations.utils import create_request_log, make_post_request, create_payment_gateway

class PaynowSettings(Document):
	supported_currencies = ["USD"]
	
	global PS_ERROR
	PS_ERROR = "Error"
	global PS_OK
	PS_OK= "Ok"
	global PS_CREATED_BUT_NOT_PAID
	PS_CREATED_BUT_NOT_PAID= "created but not paid"
	global PS_CANCELLED
	PS_CANCELLED = "cancelled"
	global PS_FAILED
	PS_FAILED= "failed"
	global PS_PAID
	PS_PAID= "paid"
	global PS_AWAITING_DELIVERY
	PS_AWAITING_DELIVERY= "awaiting delivery"
	global PS_DELIVERED
	PS_DELIVERED= "delivered"
	global PS_AWAITING_REDIRECT
	PS_AWAITING_REDIRECT = "awaiting redirect"
	
	def validate(self):
		create_payment_gateway("Paynow")
		call_hook_method('payment_gateway_enabled', gateway="Paynow")
		
		#if not self.flags.ignore_mandatory: #???

	#def on_update(self):
	#	pass

	def validate_transaction_currency(self, currency):
		if currency not in self.supported_currencies:
			frappe.throw(_("Please select another payment method. Paynow does not support transactions in currency '{0}'").format(currency))




	def parse_paynow_message(self, data):
		res = {}
		parts = data.split('&')
		for part in parts:
			indparts = part.split("=")
			res[indparts[0]] = unquote(indparts[1])
		return res


	def check_initiate_response(self, res, key):
		parts = self.parse_paynow_message(res)
		if parts['status'].upper() == "OK":
			v = parts['status'] + parts['browserurl'] + parts['pollurl']
			v += key
			hash_object = hashlib.sha512(v.encode())
			if hash_object.hexdigest().upper() == parts['hash']:
				return True
			else:
				return False
		else:
			return False
		
		
		
		
	def get_paynow_params(self, **kwargs):
		params = {		
			"reference" : kwargs.get("reference_docname"),#get from transaction
			"amount" :  kwargs.get("amount"), #get from transaction
			"id" : self.paynow_integration_id, #Keep elsewhere
			"additionalinfo" : kwargs.get("description"), # kwargs.get("payerid"),
			"authemail" : "abc@example.com",
			"status" : "Message"
			
			"""return controller.get_payment_url(**{
			"amount": flt(self.grand_total, self.precision("grand_total")),
			"title": data.company.encode("utf-8"),
			"description": self.subject.encode("utf-8"),
			"reference_doctype": "Payment Request",
			"reference_docname": self.name,
			"payer_email": self.email_to or frappe.session.user,
			"payer_name": data.customer_name,
			"order_id": self.name,
			"currency": self.currency """			
		}
		#"amount": cint(flt(self.data.amount)*100),	
		return params

	def paynow_create_url_query(self, values, mkey):
		ifields = values
		ifields['hash'] = quote(self.CreateHash(values, mkey))
		fields_string = self.UrlIfy(ifields)
		return fields_string.encode('utf-8')

	
	def create_transaction(self, **kwargs):
		
		#self, amount,title="utf-8",description="utf-8", reference_doctype="Payment Request",reference_docname="self",			payer_email="user", payer_name="name", order_id="name",currency="self.currency"):
		params = self.get_paynow_params(kwargs)
		# concertanate nd hash
				
		query_string = self.paynow_create_url_query(params, self.paynow_integration_key)
		# do a request
		paynow_request = six.moves.urllib.request.Request(self.paynow_init_url)
		result = six.moves.urllib.request.urlopen(paynow_request, query_string)
		result = result.read().decode('utf-8')
		resp=""
		if self.check_initiate_response(result, self.paynow_integration_key):
			resp = self.parse_paynow_message(result)
			#checking if request was successful
			init_status=resp['status']#reference
			pollurl=resp['pollurl']
			browserurl=resp['browserurl']
			#redirect to browser URL
			return resp
	
	
	
	
	
	
	
	def UrlIfy(self, pinfo):
		hstring = "returnurl" + '=' + pinfo['resulturl'] + '&'
		hstring += "resulturl" + '=' + pinfo['returnurl'] + '&'
		hstring += "reference" + '=' + pinfo['reference'] + '&'
		hstring += "amount" + '=' + str(pinfo['amount']) + '&'
		hstring += "id" + '=' + str(pinfo['id']) + '&'
		hstring += "additionalinfo" + '=' + pinfo['additionalinfo'] + '&'
		hstring += "authemail" + '=' + pinfo['authemail'] + '&'
		hstring += "status" + '=' + pinfo['status'] + '&'
		hstring += "hash" + '=' + pinfo['hash']
		return hstring



	def CreateHash(self, pinfo, mkey):
		#when called: 
		hstring = ""
		# To produce the proper hash, the different parts must be in joined in
		# exactly this order. So do not be tempted to loop over the dictionary as
		# it may give you a different hash on different system
		hstring += pinfo['resulturl']
		hstring += pinfo['returnurl']
		hstring += pinfo['reference']
		k=str(pinfo['amount'])
		hstring += k
		hstring += str(pinfo['id'])
		hstring += pinfo['additionalinfo']
		hstring += pinfo['authemail']
		hstring += pinfo['status']
		# add the key to end
		hstring += mkey
		hash_object = hashlib.sha512(hstring.encode())
		return hash_object.hexdigest().upper()
	
	def paynow_check_update(self, uorder, key):
		requ = urllib.request.Request(uorder.pollurl)
		result = urllib.request.urlopen(requ)
		result = result.read().decode('utf-8')
		t = paynow_check_response(result, key, uorder)
		if  t == 'paid' and uorder.status != 'paid':
			payme = parse_paynow_message(result)
			uorder.status = 'paid'
			uorder.paid = True
			uorder.confirmed_at =datetime.datetime.now()
			uorder.paynow_reference = payme['paynowreference']
			uorder.save()
			return "paid"
		else:
			return "unpaid"
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
		
	def get_payment_url(self, **kwargs):
		#payment_url = self.create_transaction(kwargs)
		#frappe.throw("URL IS: {}/{}/reference={}&amount={}".format(get_site_base_path()[2:], "api/method/paynow_gateway.paynow_gateway.doctype.paynow_settings.paynow_settings.check_if_paid?",kwargs.get("reference_docname"),kwargs.get("amount")  ) )
		params = {		
			"returnurl" : "http://{}/{}/{}!".format(get_site_base_path()[2:], "api/method/paynow_gateway.paynow_gateway.doctype.paynow_settings.paynow_settings.check_if_paid",kwargs.get("reference_docname")  ), #api post dynamic for website
			"result" : "http://dev.fineco.co.zw/orders",#redirection page after payment. shld be dynamic: fail / success OR API call which checks failure or success of txn based on ref
			"reference" : kwargs.get("reference_docname"),#get from transaction
			"amount" :  kwargs.get("amount"), #get from transaction
			"id" : self.paynow_integration_id, #Keep elsewhere
			"additionalinfo" : kwargs.get("description"),
			"authemail" : kwargs.get("payer_email"),
			"status" : "Message"}
		# concertanate nd hash
		#frappe.throw("params empty") **params ok
		query_string = self.paynow_create_url_query(params, self.paynow_integration_key)
		# do a request
		#frappe.throw(query_string) **pass**
		paynow_request = Request(self.paynow_init_url)
		
		result = urlopen(paynow_request, query_string)
		result = result.read().decode('utf-8')
		#frappe.throw(result) dope
		
		#frappe.throw(self.check_initiate_response(result, self.paynow_integration_key))
		if True: #self.check_initiate_response(result, self.paynow_integration_key):
			data=result
			#frappe.throw(data) dope
			
			res = {}
			parts = data.split('&')
			for part in parts:
				indparts = part.split("=")
				res[indparts[0]] = unquote(indparts[1])
			#frappe.throw("res func cnt print dict") dope
			resp=res
			#resp = self.parse_paynow_message(result)
			
			#checking if request was successful
			global init_status
			global pollurl
			global urlhash
			init_status=resp['status']#reference
			pollurl=resp['pollurl']
			browserurl=resp['browserurl']
			urlhash=resp['hash']
			#redirect to browser URL
			return browserurl
		
		
	def update_sys_payment(self,status):
		#doc = frappe.get_doc("Sales Invoice", reference)
		doc=self
		if status:
			doc.db_set('status', 'Authorized')
			doc.run_method('on_payment_authorized')
			
			if doc.reference_doctype and doc.reference_docname: #SINV
				ref = frappe.get_doc(doc.reference_doctype, doc.reference_docname)
				ref.run_method('on_payment_authorized')
				doc.flags.status_changed_to = "Authorized"	

		
@frappe.whitelist(allow_guest=True, xss_safe=True)
def check_if_paid(**args):
	#check if whatever transaction has been paid.... then check the corresponding transaction
	#get other arguments from poll
	
	args = frappe._dict(args)
	#posted parameters
	reference = args.get("reference")
	amount = args.get("amount")
	pollurl = 
	
	#poll paynow - create function so that you can check status
	result = urlopen(pollurl)
	result = result.read().decode('utf-8')
	pnresponse = parse_paynow_message(result)	
		
	
	paynowreference = pnresponse.get("paynowreference")
	payment_status = pnresponse.get("status")
	payment_status = payment_status.replace('+', ' ') #for two word status
	payment_status = payment_status.lower() # for comparison
	pollurl = pollurl
	paynowhash = pnresponse.get("hash")
	
	#check which transaction they match with. / use that integrations idea.?? checks after a while??
	paid = False
	#doc = frappe.get_doc("Sales Invoice", reference)
	#STAGE 1 CHECK: - INSPECT RESPONSE
	paid = False
	if payment_status == PS_PAID:
		paid = True
	elif payment_status == PS_AWAITING_DELIVERY:
		paid = True
	elif payment_status == PS_DELIVERED:
		paid = True
	else:
		paid = False
		
		
	
	
	#if paid and decimal(parts['amount'] == uorder.amount:
	if paid:
		v = args['reference']
		v += args['paynowreference']
		v += args['amount']
		v += args['status']
		v += args['pollurl']
		v += (frappe.get_doc("Paynow Settings","Paynow Gateway")).paynow_integration_key
		hash_object = hashlib.sha512((v.encode('utf-8')))
		if 1: #hash_object.hexdigest().upper() == args['hash']:
			
			frappe.throw("Payment successful")#return 'paid'
		else:
			frappe.throw("Payment UNsuccessful")#return 'unpaid'
	else:
		frappe.throw("Payment UNsuccessful")#return 'unpaid'
	
	#STAGE 2 CHECK: - INSPECT RESPONSE
	
	#doc = frappe.get_doc("Sales Invoice", reference)
	#if args["reference"]==
	
	#frappe.throw(doc.in_words)
	#doc.grand_total
	
	#'reference': 'reference', 'paynowreference': '1133713', 'amount': '54.00', 'status': 'Created', 'pollurl':', 'hash'}
	
	#check which payment is being made for which invoice
	#paynow_request = urllib.request.Request(paynow_init_url)
	
	
		
		
		
		
	@frappe.whitelist(allow_guest=True, xss_safe=True)
	def paynow_check_response_update():
		#response = create_transaction(self)
		
		
		
		if True:
			try:
						if 1:
							self.integration_request.db_set('status', 'Completed', update_modified=False)
							self.flags.status_changed_to = "Completed"
			
						else:
							frappe.log_error(str(resp), 'Stripe Payment not completed')
						
						status = frappe.flags.integration_request.status_code
					
						if self.flags.status_changed_to == "Completed":
							if self.data.reference_doctype and self.data.reference_docname:
								custom_redirect_to = None
								try:
									custom_redirect_to = frappe.get_doc(self.data.reference_doctype,
										self.data.reference_docname).run_method("on_payment_authorized", self.flags.status_changed_to)
								except Exception:
									frappe.log_error(frappe.get_traceback())
				
								if custom_redirect_to:
									redirect_to = custom_redirect_to
				
							redirect_url = '/integrations/payment-success'
						else:
							redirect_url = '/integrations/payment-failed'
							
						return {
							"redirect_to": redirect_url,
							"status": status
							}
			except:
							##else'unpaid'
							frappe.log_error(frappe.get_traceback())
							# failed
							pass

	def create_request(self, data):
		self.data = frappe._dict(data)

		try:
			self.integration_request = frappe.get_doc("Integration Request", self.data.token)
			self.integration_request.update_status(self.data, 'Queued')
			return self.authorize_payment()
		except Exception:
			frappe.log_error(frappe.get_traceback())
			return{
				"redirect_to": frappe.redirect_to_message(_('Server Error'), _("Seems issue with server's Paynow config. Don't worry, in case of failure amount will get refunded to your account.")),
				"status": 401
			}
	
		"""def authorize_payment(self):
		
		An authorization is performed when user’s payment details are successfully authenticated by the bank.
		The money is deducted from the customer’s account, but will not be transferred to the merchant’s account
		until it is explicitly captured by merchant.
		
		data = json.loads(self.integration_request.data)

		try:
			if True:
				self.integration_request.update_status(data, 'Authorized')
				self.flags.status_changed_to = "Authorized"

		except:
			frappe.log_error(frappe.get_traceback())
			# failed
			pass

		status = frappe.flags.integration_request.status_code

		redirect_to = data.get('notes', {}).get('redirect_to') or None
		redirect_message = data.get('notes', {}).get('redirect_message') or None


			redirect_url = 'payment-success'
		else:
			redirect_url = 'payment-failed'

		return {
			"redirect_to": redirect_url,
			"status": status}"""
		
		
		
		
		
		
	




	
	
	
	
	"""
	def paynow_update(self, request, order_id):
	#This the point which Paynow polls our site with a payment status. Its
	#a good idea to also poll Paynow manually just in case. I also poll it
	#when user is returned to site
		uorder = get_object_or_404(PaynowPayment, reference=order_id)
		t = paynow_check_update(uorder, self.paynow_integration_key)
		return HttpResponse(t)"""


	
	
@frappe.whitelist(allow_guest=True, xss_safe=True)
def confirm_payment(token):
	try:
		redirect = True
		status_changed_to, redirect_to = None, None

		doc = frappe.get_doc("Paynow Settings")
		

		integration_request = frappe.get_doc("Integration Request", token)
		data = json.loads(integration_request.data)

		response = make_post_request(url, data=params)

		if 1:
			redirect_url = '/integrations/payment-success'
		else:
			redirect_url = "/integrations/payment-failed"


		# this is done so that functions called via hooks can update flags.redirect_to
		if redirect:
			frappe.local.response["type"] = "redirect"
			frappe.local.response["location"] = get_url(redirect_url)

	except Exception:
		frappe.log_error(frappe.get_traceback())

def update_integration_request_status(token, data, status, error=False):
	frappe.get_doc("Integration Request", token).update_status(data, status)
