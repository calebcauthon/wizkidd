require 'curb-fu'
require 'base64'
require 'hmac-md5'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'mongo'

def get_authorization(message, publicKey, privateKey)
  hmac = HMAC::MD5.new privateKey
  hmac.update "#{publicKey}|#{message}"
  
  hmacs = hmac.to_s
  
  hash64 = Base64.strict_encode64(hmac.digest)
  
  auth = URI::encode("#{publicKey}:#{hash64}")
  
  return auth
end

def get_json_response(message)
  caleb_auth = "234328c5-1f79-8738-05a1-d132f871d075--50b6428b-8ef0-4c43-a711-6d25e13fc362BF-13-A5-6E-3E-E6-26-BB-2E-0D-FC-F4-52-35-9F-70"
  auth = caleb_auth
  
  publicKey = "234328c5-1f79-8738-05a1-d132f871d075"
  privateKey = "50b6428b-8ef0-4c43-a711-6d25e13fc362BF-13-A5-6E-3E-E6-26-BB-2E-0D-FC-F4-52-35-9F-70"
  
  authorization = get_authorization(message, publicKey, privateKey)

  response = CurbFu.get(
    :url => "http://api.fonts.com#{message}",
    :headers => {
      'Authorization' => authorization,
      'AppKey' => 'b45120b6-5c01-44ed-9646-0aac88b9c2ed1190871',
      'Password' => ''
  })

  return JSON.parse(response.body)
end
def get_xml_response(message)
  caleb_auth = "234328c5-1f79-8738-05a1-d132f871d075--50b6428b-8ef0-4c43-a711-6d25e13fc362BF-13-A5-6E-3E-E6-26-BB-2E-0D-FC-F4-52-35-9F-70"
  auth = caleb_auth
  
  caleb_publicKey = "234328c5-1f79-8738-05a1-d132f871d075"
  caleb_privateKey = "50b6428b-8ef0-4c43-a711-6d25e13fc362BF-13-A5-6E-3E-E6-26-BB-2E-0D-FC-F4-52-35-9F-70"
  
  authorization = get_authorization(message, publicKey, privateKey)

  response = CurbFu.get(
    :url => "http://api.fonts.com#{message}",
    :headers => {
      'Authorization' => authorization,
      'AppKey' => 'b45120b6-5c01-44ed-9646-0aac88b9c2ed1190871',
      'Password' => ''
  })

  doc = Nokogiri::XML(response.body)
  
  fonts = []
  project_id = doc.xpath('//Fonts/Font').each do |font|
    this_font = {}
    
    this_font["name"] = font.xpath('FontName').text
    this_font["id"] = font.xpath('FontID').text
    
    fonts.push(this_font)
  end
  
  JSON.generate(fonts)
end
def get_projects
  message = "/rest/json/Projects/?wfspstart=0&wfsplimit=500"
  response = get_response(message)
  
  list = []
  
  projects = response["Projects"]["Project"]
  projects.each do |project|
    this_project = {}
    this_project["name"] = project["ProjectName"]
    this_project["id"] = project["ProjectKey"]

    list.push(this_project)
  end
  
  list
end
def get_fonts_from_webfonts(project_id)
  message = "/rest/xml/Fonts/?wfspstart=0&wfsplimit=500&wfspid=#{project_id}"
  fonts = JSON.parse(get_xml_response(message))
  
  fonts
end
def get_fonts(project_id) 
  fonts = []
  
  one_font = {}
  one_font["name"] = "Helvetica Neue"
  one_font["id"] = "xklk1-akjd23"
  
  fonts.push(one_font)
  fonts.push(one_font)
  fonts
end
def get_domains(project_id)
  domains = []
  
  one_domain = {}
  one_domain["name"] = "www.google.com"
  one_domain["id"] = "x1a2-10df"
  
  domains.push(one_domain)
  
  domains
end
def get_all_data() 
  projects_from_webfonts = get_projects
  
  projects = []
  
  projects_from_webfonts.each do |this_project| 
    project_id = this_project["id"]
    project_name = this_project["name"]
  
    one_project = {}
    one_project["name"] = project_name
    one_project["projectID"] = project_id
    one_project["domains"] = get_domains_from_webfonts(project_id)
    one_project["fonts"] = get_fonts_from_webfonts(project_id)
    
    projects.push(one_project)
  end
  
  projects
end
def get_cached_data
  client = MongoClient.new('ds029217.mongolab.com', 29217)
  db = client['webfonts']
  auth_response = db.authenticate("intouch", "intouch")
  
  coll = db['projects']
  
  projects = coll.find
  projects  
end
def get_domains_from_webfonts(project_id)
  message = "/rest/json/Domains/?wfspstart=0&wfsplimit=500&wfspid=#{project_id}"
  response = get_response(message)
  
  list = []
  
  if(response.has_key?("Domains") && response["Domains"].has_key?("Domain"))
    domains = response["Domains"]["Domain"]

    if(domains && domains.count > 0)
      domains.each do |this_domain|
        if(this_domain.kind_of?(Hash))
          formatted_domain = {}
          formatted_domain["name"] = this_domain["DomainName"]
          formatted_domain["id"] = this_domain["DomainID"]
          list.push(formatted_domain)
        end
      end
    else
      this_domain = {}
      if(domains && domains.has_key?("DomainName"))
        this_domain["name"] = domains["DomainName"]
        this_domain["id"] = domains["DomainID"]
        
        list.push(this_domain)
      end
    end
    return list
  else
    []
  end
end
def something
  response = get_projects
  projects = response["Projects"]["Project"]
  
  projects.each do |project|
    this_project = {}
    
    domain_response = get_domains(project["ProjectKey"])
    project_name = project["ProjectName"]
    
    if(domain_response["Domains"])
      domains = domain_response["Domains"]["Domain"]
      if(domains && domains.count > 0)
        if(domains.kind_of?(Array))
          #puts "domain count: #{domains.count} for #{project_name}"
        else
          #puts "domain count: 1 for #{project_name}"
        end
        
      end
    end
  end
end
def save_projects(projects) 
  client = MongoClient.new('ds029217.mongolab.com', 29217)
  db = client['webfonts']
  auth_response = db.authenticate("intouch", "intouch")
  
  coll = db['projects']
  coll.drop
  
  projects.each do |this_project|
    coll.insert(this_project)
  end
end
