# encoding: UTF-8
require 'cora'
require 'siri_objects'
#require 'google_places'
require 'httparty'
require 'json'

%w(client location request spot).each do |file|
  require File.join(File.dirname(__FILE__), 'google_places', file)
end

class SiriProxy::Plugin::GPP < SiriProxy::Plugin
  def initialize(config)
  end
  
  filter "SetRequestOrigin", direction: :from_iphone do |object|
  puts object
  if object["properties"]["status"] != "Denied"
    @locationLat = Float(object["properties"]["latitude"])
    @locationLong = Float(object["properties"]["longitude"])
  else
	@locationLat = nil
    @locationLong = nil
  end	
  end 
  
  
 listen_for /Où suis-je/i do
	say "Recherche..."
	if @locationLat != nil && @locationLong !=nil
		url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{@locationLat},#{@locationLong}&sensor=true&language=fr-FR"
		@response = Net::HTTP.get(URI.parse(url))
		@result = JSON.parse(@response)
		puts @result
		if @result != nil
			if @result["status"] == "ZERO_RESULTS"
				say "Votre adresse n'a pas pu être déterminée. Voici une carte."
				add_views = SiriAddViews.new
				add_views.make_root(last_ref_id)
				map_snippet = SiriMapItemSnippet.new
				item = SiriMapItem.new
				item.label = "My location"
				location = SiriLocation.new
				location.latitude = @locationLat
				location.longitude = @locationLong
				item.location = location
				map_snippet.items << item
				add_views.views << map_snippet
				send_object add_views
			elsif @result["status"] == "OK"
				@fullAddress = ""
				@number = ""
				@street = ""
				@city = ""
				@state = ""
				@country = ""
				@countrycode = ""
				@postalcode = ""
				if @result["results"][0]["formatted_address"] != nil
					@fullAddress = @result["results"][0]["formatted_address"]
				end
				if @result["results"][0]["address_components"][0]["long_name"] != nil
					@number = @result["results"][0]["address_components"][0]["long_name"]
				end
				if @result["results"][0]["address_components"][1]["long_name"] !=nil
					@street = @result["results"][0]["address_components"][1]["long_name"]
				end
				if @result["results"][0]["address_components"][2]["long_name"] !=nil
					@city = @result["results"][0]["address_components"][2]["long_name"]
				end
				if @result["results"][0]["address_components"][3]["short_name"] !=nil
					@state = @result["results"][0]["address_components"][3]["short_name"]
				end
				if @result["results"][0]["address_components"][5]["long_name"] !=nil
					@country = @result["results"][0]["address_components"][5]["long_name"]
				end
				if @result["results"][0]["address_components"][5]["short_name"] !=nil
					@countrycode = @result["results"][0]["address_components"][5]["short_name"]
				end
				if @result["results"][0]["address_components"][6]["long_name"] !=nil
					@postalcode = @result["results"][0]["address_components"][6]["long_name"]
				end
				add_views = SiriAddViews.new
				add_views.make_root(last_ref_id)
				map_snippet = SiriMapItemSnippet.new
				item = SiriMapItem.new
				item.label = "My location"
				location = SiriLocation.new
				location.label = @fullAddress
				location.latitude = @locationLat
				location.longitude = @locationLong
				location.street = @street
				location.city = @city
				location.stateCode = @state
				location.countryCode = @countrycode
				location.postalCode = @postalcode
				item.location = location
				map_snippet.items << item
				add_views.views << map_snippet
				say "Vous êtes ici: #{@fullAddress}"
				send_object add_views
			else
				say "Votre adresse n'a pas pu être déterminée"
			end
		else
			say "Google Places ne répond pas actuellement. Réessayez plus tard."
		end
	else
		say "Votre position n'est pas accessible. Vérifiez que l'option de localisation est activée dans Réglages."
	end
	request_completed
 end
 
 listen_for /(Lieux supportés|Lieu supporté|Type de lieu supporte|Type de lieu supporté|Type de lieux supportés)/i do
	say "Voici les types de lieux supportés:"
	places_array = ["comptable"=>"accounting", "aéroport"=>"airport", "parc d'attraction"=>"amusement_park", "aquarium"=>"aquarium", "gallerie d'art"=>"art_gallery", "distributeur"=>"atm", "boulangerie"=>"bakery", "banque"=>"bank", "bar"=>"bar", "salon de beauté"=>"beauty_salon", "marchand de vélo"=>"bicycle_store", "librairie"=>"book_store", "bowling"=>"bowling_alley", "arrêt de bus"=>"bus_station", "café"=>"cafe", "camping"=>"campground", "concessionnaire"=>"car_dealer", "location de voiture"=>"car_rental", "garage"=>"car_repair", "lavage de voiture"=>"car_wash", "casino"=>"casino", "cimetière"=>"cemetery", "église"=>"church", "hôtel de ville"=>"city_hall", "magasin de vêtements"=>"clothing_store", "épicerie"=>"convenience_store", "palais de justice"=>"courthouse", "dentiste"=>"dentist", "hypermarché"=>"department_store", "docteur"=>"doctor", "electricien"=>"electrician", "magasin d'électronique"=>"electronics_store", "embassade"=>"embassy", "établissement"=>"establishment", "finance"=>"finance", "caserne de pompiers"=>"fire_station", "fleuriste"=>"florist", "nourriture"=>"food", "pompes funèbres"=>"funeral_home", "magasin de meubles"=>"furniture_store", "station essence"=>"gas_station", "entrepreneur"=>"general_contractor", "geocodage"=>"geocode", "supermarché"=>"grocery_or_supermarket", "salle de sport"=>"gym", "coiffeur"=>"hair_care", "quicaillerie"=>"hardware_store", "santé"=>"health", "temple hindou"=>"hindu_temple", "magasin de déco"=>"home_goods_store", "hôpital"=>"hospital", "agence d'assurance"=>"insurance_agency", "bijouterie"=>"jewelry_store", "pressing"=>"laundry", "cabinet d'avocat"=>"lawyer", "bibliothèque"=>"library", "magasin d'alcool"=>"liquor_store", "localgovernmentoffice"=>"local_government_office", "serrurier"=>"locksmith", "hébergement"=>"lodging", "livraison de repas"=>"meal_delivery", "plat à emporter"=>"meal_takeaway", "mosquée"=>"mosque", "location de films"=>"movie_rental", "cinéma"=>"movie_theater", "entreprise de déménagement"=>"moving_company", "musée"=>"museum", "boite de nuit"=>"night_club", "peintre"=>"painter", "parc"=>"park", "parking"=>"parking", "magasin animalier"=>"pet_store", "pharmacie"=>"pharmacy", "physiothérapeute"=>"physiotherapist", "lieu de culte"=>"place_of_worship", "plombier"=>"plumber", "police"=>"police", "bureau de poste"=>"post_office", "agence immobilière"=>"real_estateagency", "restaurant"=>"restaurant", "couvreur"=>"roofing_contractor", "parc à caravanes"=>"rv_park", "école"=>"school", "magasin de chaussures"=>"shoe_store", "centre commercial"=>"shopping_mall", "spa"=>"spa", "stade"=>"stadium", "stockage"=>"storage", "magasin"=>"store", "station de metro"=>"subway_station", "synagogue"=>"synagogue", "station de taxi"=>"taxi_stand", "gare"=>"train_station", "agence de voyage"=>"travel_agency", "université"=>"university", "vétérinaire"=>"veterinary_care", "zoo"=>"zoo"]
	namesArray = places_array[0].keys
	nameString = ""
	for name in namesArray do
		nameString << "#{name}, "
	end
	say "#{nameString}", spoken: ""
	request_completed
 end
 
 
 listen_for /(cherche un|cherche une) (.*)/i do |cmd, spokenPlace|
	if @locationLat != nil
		places_array = ["comptable"=>"accounting", "aéroport"=>"airport", "parc d'attraction"=>"amusement_park", "aquarium"=>"aquarium", "gallerie d'art"=>"art_gallery", "distributeur"=>"atm", "boulangerie"=>"bakery", "banque"=>"bank", "bar"=>"bar", "salon de beauté"=>"beauty_salon", "marchand de vélo"=>"bicycle_store", "librairie"=>"book_store", "bowling"=>"bowling_alley", "arrêt de bus"=>"bus_station", "café"=>"cafe", "camping"=>"campground", "concessionnaire"=>"car_dealer", "location de voiture"=>"car_rental", "garage"=>"car_repair", "lavage de voiture"=>"car_wash", "casino"=>"casino", "cimetière"=>"cemetery", "église"=>"church", "hôtel de ville"=>"city_hall", "magasin de vêtements"=>"clothing_store", "épicerie"=>"convenience_store", "palais de justice"=>"courthouse", "dentiste"=>"dentist", "hypermarché"=>"department_store", "docteur"=>"doctor", "electricien"=>"electrician", "magasin d'électronique"=>"electronics_store", "embassade"=>"embassy", "établissement"=>"establishment", "finance"=>"finance", "caserne de pompiers"=>"fire_station", "fleuriste"=>"florist", "nourriture"=>"food", "pompes funèbres"=>"funeral_home", "magasin de meubles"=>"furniture_store", "station essence"=>"gas_station", "entrepreneur"=>"general_contractor", "geocodage"=>"geocode", "supermarché"=>"grocery_or_supermarket", "salle de sport"=>"gym", "coiffeur"=>"hair_care", "quicaillerie"=>"hardware_store", "santé"=>"health", "temple hindou"=>"hindu_temple", "magasin de déco"=>"home_goods_store", "hôpital"=>"hospital", "agence d'assurance"=>"insurance_agency", "bijouterie"=>"jewelry_store", "pressing"=>"laundry", "cabinet d'avocat"=>"lawyer", "bibliothèque"=>"library", "magasin d'alcool"=>"liquor_store", "localgovernmentoffice"=>"local_government_office", "serrurier"=>"locksmith", "hébergement"=>"lodging", "livraison de repas"=>"meal_delivery", "plat à emporter"=>"meal_takeaway", "mosquée"=>"mosque", "location de films"=>"movie_rental", "cinéma"=>"movie_theater", "entreprise de déménagement"=>"moving_company", "musée"=>"museum", "boite de nuit"=>"night_club", "peintre"=>"painter", "parc"=>"park", "parking"=>"parking", "magasin animalier"=>"pet_store", "pharmacie"=>"pharmacy", "physiothérapeute"=>"physiotherapist", "lieu de culte"=>"place_of_worship", "plombier"=>"plumber", "police"=>"police", "bureau de poste"=>"post_office", "agence immobilière"=>"real_estateagency", "restaurant"=>"restaurant", "couvreur"=>"roofing_contractor", "parc à caravanes"=>"rv_park", "école"=>"school", "magasin de chaussures"=>"shoe_store", "centre commercial"=>"shopping_mall", "spa"=>"spa", "stade"=>"stadium", "stockage"=>"storage", "magasin"=>"store", "station de metro"=>"subway_station", "synagogue"=>"synagogue", "station de taxi"=>"taxi_stand", "gare"=>"train_station", "agence de voyage"=>"travel_agency", "université"=>"university", "vétérinaire"=>"veterinary_care", "zoo"=>"zoo"]
		spokenPlace = spokenPlace.gsub(/\s+/, "")
		typeOfPlace = places_array[0][spokenPlace]
		if typeOfPlace == nil
			say "Ce type de place (#{spokenPlace}) n'est pas supporté! Faites attention à ne pas utiliser de pluriel. Dites 'Lieux supportés' pour en avoir la liste."
			request_completed
		else
		say "Recherche..."
		add_views = SiriAddViews.new
		add_views.make_root(last_ref_id)
		map_snippet = SiriMapItemSnippet.new
		@client = GooglePlaces::Client.new("AIzaSyCwr_Z52xed6AZIA9trdU8Q2bIVjojxR8U")
		@places = @client.spots(@locationLat, @locationLong, :types => typeOfPlace, :radius => 15000, :language => "fr-FR")
		if @places[0] != nil
			for @place in @places do
				if @place.rating != nil 
					avg_rating = @place.rating
				else
					avg_rating = 0.0
				end		
				name = @place.name
				adress = @place.vicinity
				latitude = @place.lat
				longtitude = @place.lng
				icon = @place.icon
				location = SiriLocation.new
				location.label = name
				location.street, location.city = adress.split(/, /)
				location.latitude = latitude
				location.longitude = longtitude
				item = SiriMapItem.new
				item.label = name
				item.location = location
				map_snippet.items << item
			end	
			utterance = SiriAssistantUtteranceView.new("Voici les lieux de type '#{spokenPlace}' dans un rayon de 15km :")
			add_views.views << utterance	
			add_views.views << map_snippet
			#you can also do "send_object object, target: :guzzoni" in order to send an object to guzzoni
			send_object add_views #send_object takes a hash or a SiriObject object
		else
			say "Je n'ai trouvé aucun lieu de type '#{spokenPlace}' à moins de 15km."
		end
		end
	else
		say "Votre position n'est pas accessible. Vérifiez que l'option de localisation est activée dans Réglages."
	end
	request_completed #always complete your request! Otherwise the phone will "spin" at the user!
end
  
end
