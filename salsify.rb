#!/usr/bin/env ruby

require 'net/ftp'
require 'net/http'
require 'nokogiri'
require 'json'

SERVER_NAME = 'ftp.salsify.com'
USERNAME = 'cs-coding-example'
PASSWORD = 'Salsify_2016!codeX'
FILENAME = 'products.xml'

OPTIONAL_CHILDREN = ['Brand', 'Color', 'MSRP', 'Bottle_Size', 'Alcohol_Volume', 'Description']

SALSIFY_API = 'https://app.salsify.com/api/v1/products/'
API_KEY = 'bd5e54a4267076639e204ce0d4f12999425630d5cd5be22300deb7bf0bcc1865'

ftp = Net::FTP.new(SERVER_NAME, USERNAME, PASSWORD)

files = ftp.nlst(FILENAME)

# open file without saving locally
files.each do |file|
   xml_string = ftp.getbinaryfile( file, nil )
   doc = Nokogiri::XML( xml_string )

   # puts "#{doc}"

   doc.search('//product').each { |product|
       item_name = product['Item_Name']
       sku = product['SKU']

       p = {'SKU' => sku,
			'Item Name' => item_name
		   }
	   
	   OPTIONAL_CHILDREN.each { |o|
	       product.search(o).map { |result| 
	           if result
	               p[o] = result.text
	           end
	       }
	   }

	   # convert _ values to space, Bottle_Size and Alcohol_Volume
	   p_new = Hash.new
	   p.each { |key, value|
	       p_new[key.gsub(/_/, ' ')] = value
	   }

	   products_json = p_new.to_json

	   puts products_json

	   url = SALSIFY_API + sku
	   uri = URI.parse(url)
	   http = Net::HTTP.new(uri.host, uri.port)
	   http.use_ssl = true
	   req = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json', 'Authorization' => 'Bearer ' + API_KEY})
	   req.body = products_json
	   resp = http.request(req)
   }


end

# <products>
#     <product Item_Name="Flolion Liquoroso ba UPDATED" SKU="12364911_42">
#         <Brand>Salillina Adega UPDATED</Brand>
#         <Color>BLUE</Color>
#         <MSRP>9.99</MSRP>
#         <Bottle_Size>750mL</Bottle_Size>
#         <Alcohol_Volume>0.14</Alcohol_Volume>
#         <Description>Flamboyantly oaked acidity with a hint of earthy notes. UPDATED</Description>
#     </product>
#     <product Item_Name="Groblage Secco ba UPDATED" SKU="12364912_42">
#         <Brand>Francinues Secco UPDATED</Brand>
#         <MSRP>20</MSRP>
#         <Description>Angular barnyard notes with buttery undertones. UPDATED</Description>
#     </product>
#     <product Item_Name="Grugey Vendemmia ba UPDATED" SKU="12364913_42">
#         <Brand>Chothillo Sec UPDATED</Brand>
#         <Color>BLUE</Color>
#         <MSRP>42</MSRP>
#         <Bottle_Size>1 L</Bottle_Size>
#         <Alcohol_Volume>0.12</Alcohol_Volume>
#         <Description>Chewy tannins overshadow complex toasty cigar box flavors. UPDATED</Description>
#     </product>
#     <product Item_Name="Ghuville Piquant ba UPDATED" SKU="12364914_42">
#         <Brand>Zambes Dolce UPDATED</Brand>
#         <Color>BLUE</Color>
#         <Bottle_Size>1 L</Bottle_Size>
#         <Description>Elegant creamy food friendly hints of refined lush notes. UPDATED</Description>
#     </product>
# </products>

# {
#     "SKU": "1234",
#     "Item Name": "XYZ Name",
#     "Brand": "Generic Wine Co.",
#     "Color": "red",
#     "MSRP": "9.99",
#     "Bottle Size": "750mL",
#     "Alcohol Volume": "0.14",
#     "Description": "Example description."
# }

