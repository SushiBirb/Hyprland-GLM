#!/usr/bin/env bash
# ============================================================================
#  emoji.sh — Rofi emoji picker (self-contained, copies to clipboard)
# ============================================================================
set -euo pipefail
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
theme="$CONFIG_DIR/rofi/menu.rasi"

pick=$(sed '1,/^### DATA ###$/d' "$0" \
  | rofi -dmenu -i -theme "$theme" -p "Emoji" \
    -theme-str 'window { width: 360px; } listview { lines: 12; }' 2>/dev/null || true)

[ -n "$pick" ] && printf '%s' "${pick%% *}" | wl-copy
exit
### DATA ###
⚡ lightning magic power
✨ sparkles magic
🪄 magic wand
🌙 moon night
🌟 star glowing
⭐ star
🔥 fire flame
🐉 dragon
🦅 eagle raven
🐍 serpent snake
🦡 badger
🦁 lion
🏰 castle hogwarts
📜 scroll parchment
📖 book spell
🔮 crystal ball
🦉 owl hedwig
🗝️ key
🧙 wizard witch mage
🧪 potion
⚗️ alembic
☕ tea butterbeer
🍂 leaf autumn
❄️ snow winter
🍃 wind
🌊 wave water
🍀 clover luck
🎯 target
🔔 bell notify
✅ check ok done
❌ cross no cancel
❤️ heart love
💀 skull danger
🎉 party celebrate
🚀 rocket launch
🔍 search
⚙️ gear settings
💡 idea light
🗝 key
🗝️ key old
⚡ zap
🎭 drama theatre
✏️ pencil edit
📋 clipboard copy
🧹 broom clean
🏺 vase antique
🕯️ candle light
🌙 crescent
🐺 wolf
🕷️ spider
🦇 bat
🌫️ fog mist
🌈 rainbow
☀️ sun
⚡ energy
🎓 graduation
📜 map marauders
🏆 trophy win
🛡️ shield
⚔️ swords duel
🎯 aim
🌑 new moon
🌓 moon quarter
🌕 full moon
🪐 planet
🌠 shooting star
🦌 deer patronus
🐈 cat
🐕 dog
🐉 dragon
🦢 swan
🪶 feather quill
🔔 alert
🔕 mute
🔊 volume
🎵 music
🎶 notes
📮 mail
💌 letter
📅 calendar
⏰ alarm
⏳ hourglass
🔑 password
🔐 lock secure
🔓 unlock
♻️ recycle
🌱 sprout grow
🌳 tree
🌺 flower
🌻 sunflower
🍄 mushroom potion
🌶️ pepper
🍰 cake
🧁 cupcake
🍩 donut
🍫 chocolate
🍯 honey
🍯 butterbeer
🫖 teapot
🍷 wine
🍻 cheers
🥂 celebrate
🍕 pizza
🌮 taco
🍿 popcorn movie
🎲 dice game
🎮 gamepad
🕹️ joystick
🎸 guitar
🎻 violin
🎹 piano
🎤 mic karaoke
🎧 headphones
📷 camera
🎥 film
🎬 movie
🖼️ art frame
🎨 palette paint
✏️ write
📝 memo note
📌 pin
📎 attach
✂️ scissors
📏 ruler
📐 triangle
📦 package
🚚 delivery
📮 postbox
✉️ envelope
💌 love letter
📝 sign
💼 briefcase work
🛒 cart shop
💸 money
💳 card
💎 gem crystal
🔮 crystal ball
🕯️ candle
🪔 lamp diya
🔦 flashlight
💡 bulb
🔋 battery
🔌 plug
🧲 magnet
⚙️ gear
🔨 hammer
🛠️ tools
🔧 wrench
🔩 nut bolt
⛓️ chains
🔫 water pistol
🏹 bow arrow
🛡️ shield protect
🚪 door
🛏️ bed sleep
🛋️ couch sofa
🚿 shower
🛁 bath
🧼 soap
🪥 toothbrush
🪒 razor
🧴 lotion
🧻 tissue
🚽 toilet
🚮 trash
🧹 broom sweep
🧽 sponge
🧯 extinguisher
🛗 elevator
🪜 ladder
🪟 window
🚧 construction
⚠️ warning
🚸 children
⛔ no entry
🚫 prohibited
🆘 help
⛑️ helmet rescue
🔍 inspect
🔎 microscope
🔭 telescope
🔬 science
🧬 dna
🩺 stethoscope
💊 pill
💉 syringe vaccine
🩹 bandage
🩸 blood
🦴 bone
💀 skull death
👻 ghost
👽 alien
🤖 robot
🎃 halloween
🎄 christmas
🎆 fireworks
🎇 sparkler
🧨 firecracker
✨ celebration
🎈 balloon
🎁 gift
🎗️ ribbon
🎟️ ticket admission
🎫 ticket
🎖️ medal
🏆 trophy
🏅 sports medal
🥇 first place
🥈 second
🥉 third
⚽ soccer
🏀 basketball
🏈 football
⚾ baseball
🎾 tennis
🏐 volleyball
🏉 rugby
🥏 frisbee
🎱 billiards
🏓 ping pong
🏸 badminton
🏒 hockey
🏑 field hockey
🥍 lacrosse
🏏 cricket
🥅 goal net
⛳ golf
🏹 archery
🎣 fishing
🥊 boxing
🥋 martial arts
🎽 running
⛸️ ice skate
🛷 sled
🎿 ski
⛷️ skier
🏂 snowboarder
🪂 parachute
🏋️ weights
🤸 gymnastics
🤼 wrestling
🤽 water polo
🤾 handball
🤺 fencing
🏌️ golfing
🏄 surfing
🏊 swimming
🤽 polo
🚣 rowing
🧗 climbing
🚵 mountain bike
🚴 bike
🏆 win
🎮 play
🕹️ arcade
🎲 dice
🎯 darts
🎳 bowling
🃏 joker card
🀄 mahjong
🎴 flower cards
🎭 masks
🖼️ art
🎨 paint
✏️ sketch
🖊️ pen
🖋️ fountain pen
🖍️ crayon
📚 books
📖 reading
🔖 bookmark
📰 newspaper
🗞️ rolled newspaper
📅 date
📆 calendar tearoff
🗓️ spiral calendar
📇 card index
🗃️ card box
📦 box
📤 outbox
📥 inbox
📨 incoming
📩 envelope arrow
📧 email
💌 love letter
📩 message
💬 speech
💭 thought
🗯️ anger
♠️ spade
♥️ heart card
♦️ diamond
♣️ club
🃏 joker
🀄 dragon tile
🎴 hanafuda
🎭 comedy
🎨 art supplies
🎬 clapper
🎤 mic
🎧 audio
🎼 score
🎵 note
🎶 notes
🎚️ level slider
🎛️ knobs
📻 radio
🎷 sax
🎸 guitar
🎹 piano
🎺 trumpet
🎻 violin
🪕 banjo
🥁 drum
🪘 long drum
📱 phone
📲 phone arrow
☎️ telephone
📞 receiver
📟 pager
📠 fax
🔋 battery
🔌 plug
💻 laptop
🖥️ desktop
🖨️ printer
⌨️ keyboard
🖱️ mouse
🖲️ trackball
💽 minidisc
💾 floppy
💿 cd
📀 dvd
🧮 abacus
🎥 movie camera
🎞️ film
📽️ projector
🎬 clapper
📺 tv
📷 camera
📸 flash camera
📹 video camera
📼 vhs
🔍 search
🔎 inspect
🕯️ candle
💡 bulb
🔦 torch
🏮 lantern
🪔 lamp
📔 notebook
📕 book closed
📗 green book
📘 blue book
📙 orange book
📚 books
📖 open book
🔖 bookmark
📓 notebook
📒 ledger
📃 page curl
📄 page
📜 scroll
📰 newspaper
🗞️ news
📑 tabs
🏷️ label
💰 money bag
💴 yen
💵 dollar
💶 euro
💷 pound
💸 wings money
💳 card
🧾 receipt
💹 chart
💱 currency exchange
💲 dollar sign
✉️ envelope
📧 email
📨 incoming
📩 with arrow
📤 outbox
📥 inbox
📦 package
📫 mailbox
📪 mailbox empty
📪 closed
📬 open mail
📭 no mail
📮 postbox
🗳️ ballot box
✏️ pencil
✒️ nib
🖋️ fountain pen
🖊️ pen
🖌️ paintbrush
🖍️ crayon
📝 memo
💼 briefcase
📁 folder
📂 open folder
🗂️ dividers
📅 calendar
📆 tear-off
🗓️ spiral
📇 card index
📈 chart up
📉 chart down
📊 bar chart
📋 clipboard
📌 pushpin
📍 round pin
📎 paperclip
🖇️ linked
📏 ruler
📐 triangle
✂️ scissors
🗃️ card box
🗄️ file cabinet
🗑️ wastebasket
🔒 locked
🔓 unlocked
🔏 lock pen
🔐 key lock
🔑 key
🗝️ old key
🔨 hammer
🪓 axe
⛏️ pick
⚒️ hammer pick
🛠️ tools
🗡️ dagger
⚔️ crossed swords
💣 bomb
🪃 boomerang
🏹 bow
🛡️ shield
🚬 smoking
⚰️ coffin
⚱️ urn
🏺 amphora
🔮 crystal ball
📿 prayer beads
🧿 nazar
💈 barber pole
⚗️ alembic
🔭 telescope
🔬 microscope
🕳️ hole
💊 pill
💉 syringe
🩹 bandage
🩺 stethoscope
🩻 x-ray
🚪 door
🛏️ bed
🛋️ couch
🪑 chair
🚽 toilet
🚿 shower
🛁 bathtub
🪒 razor
🧴 lotion
🧷 safety pin
🧹 broom
🧺 basket
🧻 paper
🧼 soap
🧽 sponge
🧯 extinguisher
🛒 cart
🚬 cigarette
⚰️ casket
⚱️ urn
🗿 moai
🪧 placard
🪪 id card
🚸 crossing
🚦 traffic light
🚧 barrier
🎣 rod
🪝 hook
🪞 mirror
🪟 window
🛗 elevator
🪜 ladder
🧸 teddy
🪆 nesting dolls
🪡 needle
🧵 thread
🧶 yarn
🧷 pin
🛍️ shopping bags
🎁 gift
🎈 balloon
🎏 carp streamer
🎀 ribbon
🎊 confetti ball
🎉 party popper
🎎 dolls
🏮 lantern
🎐 wind chime
🧧 red envelope
✉️ letter
📩 received
📨 incoming
📧 email
💌 love letter
📥 inbox
📤 outbox
📦 package
🏷️ label
📪 closed mail
📬 open mail
📫 mailbox
📭 no mail
📮 postbox
🗳️ ballot
✏️ pencil
✒️ nib
🖋️ pen
🖊️ ballpoint
🖌️ brush
🖍️ crayon
📝 memo
📁 folder
📂 open folder
🗂️ dividers
📅 calendar
📆 tear off
🗓️ spiral
📇 index
📈 up
📉 down
📊 bar
📋 clipboard
📌 pin
📍 round pin
📎 clip
🖇️ links
📏 ruler
📐 triangle
✂️ scissors
🗃️ box
🗄️ cabinet
🗑️ bin
🔒 lock
🔓 unlock
🔏 lock pen
🔐 key lock
🔑 key
🗝️ old key
🔨 hammer
🪓 axe
⛏️ pick
⚒️ hammer pick
🛠️ tools
🗡️ dagger
⚔️ swords
💣 bomb
🪃 boomerang
🏹 bow
🛡️ shield
🚬 smoking
⚰️ coffin
⚱️ urn
🏺 vase
🔮 crystal
📿 beads
🧿 nazar
💈 pole
⚗️ alembic
🔭 telescope
🔬 microscope
🕳️ hole
Shop
🛒 cart
🛍️ bags
🎁 gift
🎈 balloon
🎀 ribbon
🎊 confetti
🎉 popper
🎎 dolls
🏮 lantern
🎐 chime
🧧 envelope
🪅 pinata
🪆 dolls
🧸 teddy
🖼️ frame
🎨 palette
🧵 thread
🪡 needle
🧶 yarn
🧷 pin
🧥 coat
🥼 lab coat
👙 bikini
👚 woman clothes
👕 tshirt
👖 jeans
🧣 scarf
🧤 gloves
🧥 coat
🧦 socks
👗 dress
👘 kimono
🥻 sari
🩱 one piece
🩲 briefs
🩳 shorts
👙 swim
🩰 ballet shoes
🥿 flat
👠 heel
👡 sandal
👢 boot
👟 sneaker
🥾 hiking
🧦 socks
🧤 gloves
🧣 scarf
🎩 top hat
🧢 cap
👒 woman hat
🎓 grad cap
🪖 military helmet
⛑️ rescue helmet
👑 crown
💍 ring
👝 clutch
👛 purse
👜 bag
💼 briefcase
🎒 backpack
🧳 luggage
👓 glasses
🕶️ sunglasses
🥽 goggles
🥽 goggles
🦺 vest
🧥 coat
🐶 dog
🐱 cat
🐭 mouse
🐹 hamster
🐰 rabbit
🦊 fox
🐻 bear
🐼 panda
🐻‍❄️ polar bear
🐨 koala
🐯 tiger
🦁 lion
🐮 cow
🐷 pig
🐸 frog
🐵 monkey
🐔 chicken
🐧 penguin
🐦 bird
🐤 chick
🦆 duck
🦅 eagle
🦉 owl
🦇 bat
🐺 wolf
🐗 boar
🐴 horse
🦄 unicorn
🐝 bee
🐛 worm
🦋 butterfly
🐌 snail
🐞 ladybug
🐜 ant
🪲 beetle
🦗 cricket
🕷️ spider
🦂 scorpion
🦟 mosquito
🪰 fly
🪱 worm
🐢 turtle
🐍 snake
🦎 lizard
🦖 t-rex
🦕 sauropod
🐙 octopus
🦑 squid
🦐 shrimp
🦞 lobster
🦀 crab
🐡 puffer
🐠 tropical fish
🐟 fish
🐬 dolphin
🐳 whale
🐋 spout
🦈 shark
🐊 crocodile
🐅 tiger
🐆 leopard
🦓 zebra
🦍 gorilla
🦧 orangutan
🐘 elephant
🦛 hippo
🦏 rhino
🐪 camel
🐫 bactrian
🦒 giraffe
🦘 kangaroo
🦬 bison
🐃 water buffalo
🐂 ox
🐄 cow
🐎 horse
🐖 pig
🐏 ram
🐑 sheep
🦙 llama
🐐 goat
🦌 deer
🐕 dog
🐩 poodle
🦮 guide dog
🐕‍🦺 service dog
🐈 cat
🐈‍⬛ black cat
🦃 turkey
🐓 rooster
🦚 peacock
🦜 parrot
🦢 swan
🦩 flamingo
🕊️ dove
🐇 rabbit
🦝 raccoon
🦨 skunk
🦡 badger
🦫 beaver
🦦 otter
🦥 sloth
🐁 mouse
🐀 rat
🐿️ chipmunk
🦔 hedgehog
🐾 paw prints
🐉 dragon
🐲 dragon face
🌵 cactus
🎄 tree
🌲 evergreen
🌳 deciduous
🌴 palm
🪵 wood
🌱 seedling
🌿 herb
☘️ shamrock
🍀 four leaf
🎍 bamboo
🪴 potted plant
🍃 leaves
🍂 fallen leaf
🍁 maple
🍄 mushroom
🌾 wheat
💐 bouquet
🌷 tulip
🌹 rose
🥀 wilted
🌺 hibiscus
🌼 blossom
🌻 sunflower
🌼 daisy
🌸 cherry blossom
🏵️ rosette
🍓 strawberry
🍒 cherry
🍎 apple
🍐 pear
🍊 tangerine
🍋 lemon
🍌 banana
🍉 watermelon
🍇 grapes
🫐 blueberries
🍈 melon
🍍 pineapple
🥥 coconut
🥝 kiwi
🍅 tomato
🍆 eggplant
🥑 avocado
🥦 broccoli
🥬 greens
🥒 cucumber
🌶️ pepper
🫑 bell pepper
🌽 corn
🥕 carrot
🧄 garlic
🧅 onion
🥔 potato
🍠 sweet potato
🥐 croissant
🥯 bagel
🍞 bread
🥖 baguette
🧀 cheese
🥚 egg
🍳 cooking
🧈 butter
🥞 pancakes
🧇 waffle
🥓 bacon
🥩 meat
🍗 poultry
🍖 bone in
🌭 hotdog
🍔 burger
🍟 fries
🍕 pizza
🥪 sandwich
🥙 gyro
🧆 falafel
🌮 taco
🌯 burrito
🥗 salad
🥘 paella
🫕 fondue
🥫 canned
🦪 oyster
🍝 pasta
🍜 ramen
🍲 stew
🍛 curry
🍣 sushi
🍱 bento
🥟 dumpling
🦪 oyster
🍤 shrimp
🍙 rice ball
🍚 rice
🍘 cracker
🍢 oden
🍣 sushi
🍥 fishcake
🥮 mooncake
🥠 fortune
🥡 takeout
🍦 soft serve
🍧 shaved ice
🍨 ice cream
🍩 donut
🍪 cookie
🎂 birthday cake
🍰 shortcake
🧁 cupcake
🥧 pie
🍫 chocolate
🍬 candy
🍭 lollipop
🍮 custard
🍯 honey
🍼 bottle
🥛 milk
☕ coffee
🍵 tea
🍶 sake
🍾 champagne
🍷 wine
🍸 cocktail
🍹 tropical
🍺 beer
🍻 beers
🥂 clink
🥃 tumbler
🥤 cup straw
🧋 bubble tea
🧃 juice box
🧉 mate
🧊 ice
🥢 chopsticks
🍽️ plate fork knife
🍴 fork knife
🥄 spoon
🔪 knife
🏺 amphora
🌍 globe europe
🌎 globe americas
🌏 globe asia
🌐 globe meridian
🗺️ world map
🗾 japan map
🧭 compass
🏔️ snow mountain
⛰️ mountain
🌋 volcano
🗻 fuji
🏕️ camping
🏖️ beach
🏜️ desert
🏝️ island
🏞️ national park
🏟️ stadium
🏛️ classical building
🏗️ construction
🧱 brick
🪨 rock
🪵 wood
🛖 hut
🏘️ houses
🏚️ derelict
🏠 house
🏡 house garden
🏢 office building
🏣 japanese post
🏤 post office
🏥 hospital
🏦 bank
🏨 hotel
🏩 love hotel
🏪 store
🏫 school
🏬 department
🏭 factory
🏯 japanese castle
🏰 castle
💒 wedding
🗼 tower
🗽 statue of liberty
⛪ church
🕌 mosque
🛕 hindu temple
🕍 synagogue
⛩️ shinto shrine
🕋 kaaba
⛲ fountain
⛺ tent
🌁 foggy
🌃 night
🏙️ skyline
🌄 sunrise mountain
🌅 sunrise
🌆 city dusk
🌇 city sunset
🌉 bridge night
♨️ hot springs
🎠 carousel
🎡 ferris wheel
🎢 rollercoaster
💈 pole
🎪 circus
🚂 locomotive
🚃 train car
🚄 high speed train
🚅 bullet train
🚆 train
🚇 metro
🚈 light rail
🚉 station
🚊 tram
🚝 monorail
🚞 mountain railway
🚋 tram car
🚌 bus
🚍 oncoming bus
🚎 trolleybus
🚐 minibus
🚑 ambulance
🚒 fire engine
🚓 police car
🚔 oncoming police
🚕 taxi
🚖 oncoming taxi
🚗 car
🚘 oncoming car
🚙 suv
🛻 pickup
🚚 truck
🚛 articulated
🚜 tractor
🏍️ motorcycle
🛵 scooter
🦽 manual wheelchair
🦼 motorized wheelchair
🛺 auto rickshaw
🚲 bike
🛴 scooter
🛹 skateboard
🚏 bus stop
🛣️ motorway
🛤️ railway track
🛢️ oil drum
⛽ fuel pump
🚨 police light
🚥 traffic light
🚦 traffic light
🛑 stop sign
🚧 construction
⚓ anchor
⛵ sailboat
🛶 canoe
🚤 speedboat
🛳️ passenger ship
⛴️ ferry
🛥️ motor boat
🚢 ship
✈️ airplane
🛩️ small airplane
🛫 plane takeoff
🛬 plane landing
🪂 parachute
💺 seat
🚁 helicopter
🚟 suspension railway
🚠 mountain cableway
🚡 aerial tramway
🛰️ satellite
🚀 rocket
🛸 flying saucer
🛎️ bellhop bell
🧳 luggage
⌛ hourglass done
⏳ hourglass
⌚ watch
⏰ alarm clock
⏱️ stopwatch
⏲️ timer
🕰️ mantelpiece clock
🕛 twelve o clock
🕧 twelve thirty
🕐 one
🕜 one thirty
🕑 two
🕝 two thirty
🕒 three
🕞 three thirty
🕓 four
🕟 four thirty
🕔 five
🕠 five thirty
🕕 six
🕡 six thirty
🕖 seven
🕢 seven thirty
🕗 eight
🕣 eight thirty
🕘 nine
🕤 nine thirty
🕙 ten
🕥 ten thirty
🕚 eleven
🕦 eleven thirty
🌑 new moon
🌒 waxing crescent
🌓 first quarter
🌔 waxing gibbous
🌕 full moon
🌖 waning gibbous
🌗 last quarter
🌘 waning crescent
🌙 crescent moon
🌚 new moon face
🌜 first quarter face
🌛 last quarter face
🌡️ thermometer
☀️ sun
🌝 full moon face
🌞 sun with face
🪐 ringed planet
🌟 glowing star
⭐ star
🌠 shooting star
🌌 milky way
☁️ cloud
⛅ sun behind cloud
⛈️ cloud lightning rain
🌤️ sun behind small cloud
🌥️ sun behind large cloud
🌦️ sun behind rain cloud
🌧️ cloud rain
🌨️ cloud snow
🌩️ cloud lightning
🌪️ tornado
🌫️ fog
🌬️ wind face
🌀 cyclone
🌈 rainbow
🌂 closed umbrella
☂️ umbrella
☔ umbrella with rain
⛱️ umbrella on ground
⚡ high voltage
❄️ snowflake
☃️ snowman
⛄ snowman without snow
☄️ comet
🔥 fire
💧 droplet
🌊 wave