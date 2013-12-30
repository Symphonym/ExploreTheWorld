
-- Question attributes
--[[

		ID = 0, -- Unique identifier of the question, used when searching
		name = "", -- Name/title of the question
		category = "", -- Category of the question, of which it is sorted by
		texturepath = "", -- Texture displayed alongside the question
		texturewidth = 0, -- Width of the aforementioned texture
		textureheight = 0, -- Height of the aforementioned texture
		textureCropLeft = 0, -- Texture cropping data
		textureCropRight = 0,
		textureCropTop = 0,
		textureCropBottom = 0,
		modelId = 0,  -- Encrypted displayId of the npc, used instead of modelPath
		modelZoom = 0  -- Zooming factor when displaying a "modelPath" model, smaller value equals bigger model and vice versa
		modelPath = "", -- Encrypted path to the model to display, used instead of modelId
		modelYOffset = 0, -- Y offset of the model to display
		description = "", -- String of the question
		answer = "", -- Table of hashed strings of the ANSWER to the question
		zoneUnlockHash = "", -- Table of hashed strings of the name of the ZONE that unlocks the question
		itemUnlockHash = "", -- Table of hashed strings of the ID of the ITEM that unlocks the question
		npcUnlockHash = "", -- Table of hashed strings of the name of the NPC that unlocks the question
		worldObjectUnlockHash = "", -- Hashed string of the name of the READABLE OBJECT that unlocks the question
		progressUnlockHash = "", -- Hashed string of the COMPLETED QS number that unlocks the question
		zoneRequirementUnlockHash = "", -- Optional unlock argument, Hashed string of the name of the ZONE that you must be at to unlock the question
		zoneRequirementUnlockCopy = true, -- If true, the contents of zoneRequirementUnlockHash will be equal to that of zoneRequirementHash
		zoneRequirementHash = "", -- Table of hashed strings of the name of the ZONE that you must be at to answer the question
		author = "" -- Name of the person who made the question, defaults to addon author"
	},

]]



ETW_LoreQuestions = {
	
	{
		ID = 1,
		name = "The TV Chef",
		category = ETW_TRACKING_CATEGORY,
		modelId = "Mzc2NDU=",
		description = "A reference to a famous TV chef, most notably known for his hosting of various competitive cooking shows, often in quite the angry mood. Although here we have him relaxing at qutie the resort, with hot springs and steamy food just around the corner.",
		answer = {"f58b1a0e27867ef20567fd832481aed54e152c46a1c07ed4f9c3aeef8b27e790"},
		zoneRequirementHash = {"8d0ff8c7feb9ef111a36d09695309f0cd808c38b420626ac2edd2b9531bac61d"}
	},
	{
		ID = 2,
		name = "Sorrow by Quilboar",
		category = ETW_TRACKING_CATEGORY,
		modelId = "Mzg1NQ==",
		description = "Living a dry barren land this poor orc had his wife killed by the quilboar, but sought revenge on them through helpfull heroes of the Horde. Not too far from the watch post he resides, consumed by his hatred against the quilboar.",
		answer = {"3007b3f7b3762071034b5525693b2be41c01a210b5725669975dabc5be855e4f"},
		zoneRequirementHash = {"8231b7f748e85a746e443e3e16371c434fe51068382472029cad77f64af40fd1"}
	},
	{
		ID = 3,
		name = "\"Defenseless\" critters",
		category = ETW_INVESTIGATION_CATEGORY,
		modelId = "MzI4",
		description = "Green plains, plainstriders and kodos are just a few of the things you can find in this zone. Not to mention, critters such as rabbits and prairie dogs can be found using weapons here. Amongst these critters is a decorated stone, name one thing on the stone.",
		answer = {"e3bfe7e56a821737615132e603dbe6beaf6936710f634d4573250b784e58ae56", "994375f2f240a510dc3af273547d2a553afbea00b088a4f57871ab45c544becd", "edfce16ce1f01e070207fafeadbe6f498516e54cf97292d18c6b3823e893f175", "3e9e7a46c3b80b73483e3129771401ccdaed1d2eff632a824984d489a86a5dea"},
		zoneRequirementHash = {"798f715b8bfe09111da2750514181ac9f9eaf1f7a5333ba41bfe907fbdea9df5"}
	},
	{
		ID = 4,
		name = "Consumed by shadows",
		category = ETW_EXPLORE_CATEGORY,
		modelId = "NTQzMA==",
		description = "Hidden in a secret cave, one of the lesser known Demon Hunters can be found. Should you fall into this void, fear not, for the Cenarion Circle will be able to help you away from the ghosts in the darkness.",
		answer = {"088b0b86b90297d53e81ffe6efe6a13519398e4afc7bd282907cc9e6828f859a"}
	},
	{
		ID = 5,
		name = "Steel wool producer",
		category = ETW_TRACKING_CATEGORY,
		modelId = "NDA1MQ==",
		description = "A gnome with a secret farm of wool producing animals located on a beautiful grasscovered hillside. One of these animals is \"modified\" to suit other needs which we do not know of other than to amuse rude adventurers passing by.",
		answer = {"8ccff692cd12807cf8ac17e31472f44ef0a00d586534150a865bfb7a2714d14a"},
		zoneRequirementHash = {"736aaecfc1f584a92486b54aab7ba65d94e6870d5fc4413daa3abca296b4ef0b"}
	},
	{
		ID = 6,
		name = "Kill for Booty",
		category = ETW_EXPLORE_CATEGORY,
		modelPath = "V29ybGRcXEF6ZXJvdGhcXHN0cmFuZ2xldGhvcm5cXHBhc3NpdmVkb29kYWRzXFxydWluc1xcc3RyYW5nbGV0aG9ybnJ1aW5zMDIubWR4",
		description = "It was built by the ancient jungle trolls but is now reclaimed by the surrounding vegetation. Although occasionally a short fellow bribes adventurers to once again fill the long forgotten battle ring, with blood.",
		answer = {"c2f3d971eafd12bef1e2226678e96ca8a3f5dcd372d61cd77c10c67780965cd4"},
		zoneRequirementHash = {"2a373dec3bde04f90e30284c48c1e583082ea3a61dbe94be0dc9bc935fa20e44"}
	},
	{
		ID = 7,
		name = "The assassinator",
		category = ETW_TRACKING_CATEGORY,
		modelId = "NTUyOA==",
		description = "A grand master in the fine artmanship of assassinating designated targets, even a leader in a league teaching just that. Located in a training camp up in the mountains, east from the mill, and north from the south.",
		answer = {"11ee54b26794b998c485503886d3649b3a82b9c46578fb664704afb1c14f57d3"},
		zoneRequirementHash = {"0dc11dfaf6c36a4bb6570560942a387182b38b898bf5a82155622fc89df0e464"}
	},
	{
		ID = 8,
		name = "Hidden between lands",
		category = ETW_INVESTIGATION_CATEGORY,
		modelPath = "V29ybGRcXEdlbmVyaWNcXGR3YXJmXFxwYXNzaXZlIGRvb2RhZHNcXGJhdHRsZW1lbnRzXFxkd2FydmVuYmF0dGxlbWVudG1vc3N5MDIubWR4",
		modelZoom = 7,
		description = "Just south of the overpass combining highlands with wetlands is a now abandoned dwarven city. What may not be known to all is something hidden in the surrounding mountains, what is it?",
		answer = {"0219f20d577c297930f0b758f6a140f522174b3a142b9d278d8937c4c0125fbc", "e4755cb31c0fffb72499cb3f86cbbceda5ba47c5c7693aa58af164e54d64024b", "3379897f09bbf26bc35f553e9396f58e83a903573995dd110f262c3d136d84a8"},
		zoneRequirementHash = {"d05b2fc34d0e44c9fb14f601d1794ae1755e91f373d7c679e51ccba0cb34f56a"}
	},
	{
		ID = 9,
		name = "Trogg liberty",
		category = ETW_EXPLORE_CATEGORY,
		modelId = "NTk0NQ==",
		description = "Carved out of stone as a symbol for liberty, now held captive by trogg that has overrun the excavation site. Not even adventurers from the nearby lodge or loch has bothered to dig her up out of the dirt.",
		answer = {"1a7750fb59a30dbe4133444d07a45910edcce9bb4f7e5be2293c83c4d7434cab"}
	},
	{
		ID = 10,
		name = "Requirement: Be rich",
		category = ETW_EXPLORE_CATEGORY,
		modelPath = "V29ybGRcXEdlbmVyaWNcXGdvYmxpblxccGFzc2l2ZWRvb2RhZHNcXGJlZHNcXGdvYmxpbl9ob3JkZV9vcm5hdGViZWRfMDEubWR4",
		modelZoom = 2,
		description = "A luxurious retreat for the richest of business men, complete with endless hordes of servants and a pool making use of the finest engineering has to offer. Assuming you have highly positioned friends within the cartel, bring a few million gold to fully experience this palace.",
		answer = {"483c193d49c8a7fd30802ae41eb73746e3484de4cfda55d412165f02f60f2445"}
	},
	{
		ID = 11,
		name = "Trapped by bears",
		category = ETW_INVESTIGATION_CATEGORY,
		modelId = "NzA3",
		description = "By the western edge of the region that is home to the great forge we find a camp that appears to be overrun by wild animals. But where are the owners of this small camp, surely they must be nearby as the fire is still burning.",
		answer = {"dbc75b42b12c2a1ddccb94ade789aa654c5577702ad40c043f65b70873d7e02e", "e1f5380ecdd7e582eb7ae4cf3e93498877974dd38bf4fa8b0f5a5fdc6177477a", "f8565e1aa585890db7a5be060456734036c909cd28ea4d448de7206c8e26b54c"},
		zoneRequirementHash = {"73b5f5b9f0766caa35b01c58a76c0ebe71d8939f7de881ea108b4b25742e8ce6"}
	},
	{
		ID = 12,
		name = "House of Wolves",
		category = ETW_EXPLORE_CATEGORY,
		modelYOffset = 0.8,
		modelPath = "V29ybGRcXEV4cGFuc2lvbjAzXFxkb29kYWRzXFx3b3JnZW5cXGl0ZW1zXFx3b3JnZW5fc3RhZ2Vjb2FjaF8wMS5tZHg=",
		description = "Standing strong throughout the effects of the cataclysm as its surrounding areas begin to crumble down the cliffside into the water. At the top of the hill we find this manor owned by those who transform at fullmoon.",
		answer = {"157f113b8b3695becf1f1f4462c79f2adb8e095ab5151f1d022f027e93e89f24"},
		zoneRequirementHash = {"fdb767ca3ec0d0d14f9c6ab095559d20aff15776b8c6e36170612966c83fc0af"}
	},
	{
		ID = 13,
		name = "The collector",
		category = ETW_TRACKING_CATEGORY,
		modelId = "MTE2NTM=",
		description = "As one of the few non-hostile Lost Ones he urges for more things to collect, often offering a small reward to adventures who bring something new. Found in a land blasted by magic, crawling with demons and other vile sorcery.",
		answer = {"78f420f27817ed2dd63e224282b301a6957efb9df4ae6aacafbc80dd43a1e771"},
		zoneRequirementHash = {"2a0fd71aa349b3c662105e52d182b2950325ca79f408064b351575b983dfebcb"}
	},
	{
		ID = 20,
		name = "Robo-chicken mystery",
		category = ETW_INVESTIGATION_CATEGORY,
		modelId = "NzkyMA==",
		modelYOffset = 0.1,
		description = "There are three robot chickens that can be found in Azeroth, all wanted back by their owner in Booty Bay. What you might not know about these chickens is that they each have 2 unique letters at the end of their name, what do they mean?",
		answer = {"4869f908f491b6f5c9c6eb3f0eab004f54137fc7e36fe9800de5f14486fed4e9", "4405b6709391f7bc2833d5f4d1432c6e13a0613f98bf794280833afa1f7e3c53", "d75d71989b25d8114bdeeedd4f36d9b5fb8ba548ae1a66cf52329cb691330a7b", "539df6fa9856df0ed841122d035951e55517580932eb38cf934a1716570d8436", "331358067956b956143d4a8b207df3121f0f97dcd0ed8aa26d2e3bdbd2b8716b"},
		zoneRequirementHash = {"e9288d744b1ba953b6ac213c87456c57aeda811cd2fca0044c2f432484328cda","d75d71989b25d8114bdeeedd4f36d9b5fb8ba548ae1a66cf52329cb691330a7b", "4405b6709391f7bc2833d5f4d1432c6e13a0613f98bf794280833afa1f7e3c53"},
		zoneRequirementUnlockCopy = true,
		npcUnlockHash = {"eafcacdb00a30f261075633efd368a23c530de2de46672c379142f583939bb5e","8bee34cab7ae493f2848ff7fb527b0d038152f8e382f924e3a11b70835e1883f","45248be447123432752c81cd0995afab05fc0e5d80d2d622187144f6fa3cfd67"}
	}


}

-- Stores hashtables on zones/npcs/other with a bunch of questions as values
ETW_UnlockTable = {}

ETW_UnlockTable.zones = {}
ETW_UnlockTable.items = {}
ETW_UnlockTable.npcs = {}
ETW_UnlockTable.worldObjects = {}
ETW_UnlockTable.progress = {}