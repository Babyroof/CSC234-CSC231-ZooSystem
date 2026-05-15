// seed_service.dart
// ใช้สำหรับเพิ่มข้อมูลทีเดียวลง Firebase Firestore
// วิธีใช้: เรียก SeedService().seedAll() จาก initState หรือ button ใน dev mode เท่านั้น

import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // SEED ALL (animals + zones)
  // ─────────────────────────────────────────
  Future<void> seedAll() async {
    print('🌱 Starting seed...');
    await _seedZones();

    final check = await _db.collection('zone').get();
    print('✅ Zones in DB: ${check.docs.length}');
    for (var doc in check.docs) {
      print('Zone found: ${(doc.data())['zoneName']}');
    }

    await _seedAnimals();
    print('✅ Seed completed!');
  }

  // ─────────────────────────────────────────
  // MIGRATE (bookings + addOns + config)
  // ─────────────────────────────────────────
  Future<void> migrateAll() async {
    print('🗑️ Clearing bookings...');
    await _clearCollection('booking');

    print('🌱 Seeding addOns...');
    await _clearCollection('addOns');
    await _seedAddOns();

    print('🌱 Seeding config...');
    await _seedConfig();

    print('🌱 Seeding sample bookings...');
    await _seedBookings();

    print('✅ Migration done!');
  }

  // ใช้เมื่อต้องการ re-seed addOns อย่างเดียว
  Future<void> reseedAddOns() async {
    print('🌱 Re-seeding addOns...');
    await _clearCollection('addOns');
    await _seedAddOns();
    print('✅ addOns re-seeded!');
  }

  Future<void> _clearCollection(String name) async {
    final snap = await _db.collection(name).get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
    print('🗑️ Deleted ${snap.docs.length} docs from $name');
  }

  Future<void> _seedAddOns() async {
    final addOns = [
      {'name': 'Buffet Food', 'price': 200, 'priceType': 'per_person',  'isActive': true, 'order': 1},
      {'name': 'Guid Tour',   'price': 350, 'priceType': 'per_booking', 'isActive': true, 'order': 2},
      {'name': 'Golf Car',    'price': 500, 'priceType': 'per_booking', 'isActive': true, 'order': 3},
    ];

    for (var addOn in addOns) {
      await _db.collection('addOns').add(addOn);
      print('Added addOn: ${addOn['name']}');
    }
  }

  Future<void> _seedConfig() async {
    await _db.collection('config').doc('pricing').set({
      'adultPrice': 300,
      'childPrice': 150,
      'elderPrice': 40,
    });
    print('Added config/pricing');
  }

  Future<void> _seedBookings() async {
    // ✏️ วาง userId จาก Firebase Console → user collection → copy document ID
    const String userId = 'PASTE_USER_ID_HERE';

    final addOnSnap = await _db.collection('addOns').get();
    final addOnMap = {
      for (var doc in addOnSnap.docs)
        (doc.data())['name'] as String: {
          'id': doc.id,
          'name': doc.data()['name'],
          'price': doc.data()['price'],
          'priceType': doc.data()['priceType'],
        }
    };

    final bookings = [
      // Booking 1 — adult + elder, no addOns, Pending
      {
        'userId': '/user/$userId',
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'adultTotal': 2,
        'childTotal': 0,
        'elderTotal': 1,
        'selectedAddOns': [],
        'totalPrice': (2 * 300) + (1 * 40), // 640
        'chargeId': 'chrg_test_sample001',
        'status': 'Pending',
      },
      // Booking 2 — adult + child + Buffet Food (per_person), Pending
      {
        'userId': '/user/$userId',
        'date': Timestamp.fromDate(DateTime(2026, 6, 5)),
        'adultTotal': 1,
        'childTotal': 2,
        'elderTotal': 0,
        'selectedAddOns': [addOnMap['Buffet Food']],
        'totalPrice': (1 * 300) + (2 * 150) + (200 * 3), // 1200 (buffet x3 people)
        'chargeId': 'chrg_test_sample002',
        'status': 'Pending',
      },
      // Booking 3 — adult + child + Golf Car + Guid Tour (per_booking), Done
      {
        'userId': '/user/$userId',
        'date': Timestamp.fromDate(DateTime(2026, 6, 10)),
        'adultTotal': 3,
        'childTotal': 1,
        'elderTotal': 0,
        'selectedAddOns': [addOnMap['Golf Car'], addOnMap['Guid Tour']],
        'totalPrice': (3 * 300) + (1 * 150) + 500 + 350, // 1900
        'chargeId': 'chrg_test_sample003',
        'status': 'Done',
      },
      // Booking 4 — elder only, all addOns, Cancelled
      {
        'userId': '/user/$userId',
        'date': Timestamp.fromDate(DateTime(2026, 5, 22)),
        'adultTotal': 0,
        'childTotal': 0,
        'elderTotal': 2,
        'selectedAddOns': [
          addOnMap['Buffet Food'],
          addOnMap['Guid Tour'],
          addOnMap['Golf Car'],
        ],
        'totalPrice': (2 * 40) + (200 * 2) + 350 + 500, // 1230 (buffet x2 elders)
        'chargeId': 'chrg_test_sample004',
        'status': 'Cancelled',
      },
      // Booking 5 — family, no addOns, Done
      {
        'userId': '/user/$userId',
        'date': Timestamp.fromDate(DateTime(2026, 6, 15)),
        'adultTotal': 2,
        'childTotal': 3,
        'elderTotal': 1,
        'selectedAddOns': [],
        'totalPrice': (2 * 300) + (3 * 150) + (1 * 40), // 1090
        'chargeId': 'chrg_test_sample005',
        'status': 'Done',
      },
    ];

    for (var booking in bookings) {
      await _db.collection('booking').add(booking);
      print('Added booking: ${booking['status']} — ${booking['date']}');
    }
  }

  // ─────────────────────────────────────────
  // ZONES
  // ─────────────────────────────────────────
  Future<void> _seedZones() async {
    final zones = [
      {'zoneName': 'Asia',         'location_x': 120.0, 'location_y': 80.0},
      {'zoneName': 'Africa',       'location_x': 340.0, 'location_y': 200.0},
      {'zoneName': 'Australia',    'location_x': 560.0, 'location_y': 320.0},
      {'zoneName': 'South America','location_x': 200.0, 'location_y': 420.0},
      {'zoneName': 'Freezing',     'location_x': 480.0, 'location_y': 80.0},
    ];

    for (var zone in zones) {
      await _db.collection('zone').add(zone);
      print('Added zone: ${zone['zoneName']}');
    }
  }

  // ─────────────────────────────────────────
  // ANIMALS
  // ─────────────────────────────────────────
  Future<void> _seedAnimals() async {
    final zoneSnap = await _db.collection('zone').get();
    final zoneMap = {
      for (var doc in zoneSnap.docs)
        (doc.data())['zoneName'] as String: doc.reference,
    };

    final animals = [
      // ════════════════════════════════
      // 🌏 ASIA
      // ════════════════════════════════
      {
        'animalName': 'Asian Elephant',
        'animalDetail':
            'The Asian Elephant is the largest land animal in Asia and one of the most intelligent creatures on Earth. '
            'Unlike their African cousins, Asian elephants have smaller, rounded ears, a more rounded back, and a single '
            '"finger" at the tip of their trunk. They live in herds led by the oldest female and communicate through deep '
            'rumbles, some below the range of human hearing. In the wild, a single elephant can consume up to 150 kg of '
            'vegetation per day. Sadly, habitat loss and human conflict have made them an endangered species.',
        'animalPicture': '',
        'zoneId': zoneMap['Asia'],
        'location_x': 100.0,
        'location_y': 60.0,
      },
      {
        'animalName': 'Tiger',
        'animalDetail':
            'The Tiger is the largest wild cat in the world and one of Asia\'s most iconic predators. With their striking '
            'orange coat and bold black stripes — unique to every individual like a human fingerprint — tigers are built for '
            'stealth and power. They are solitary hunters, capable of leaping up to 10 meters in a single bound. Thailand is '
            'home to the Indochinese Tiger, a subspecies now critically threatened by poaching and deforestation. '
            'Each tiger\'s roar can be heard from over 3 kilometers away.',
        'animalPicture': '',
        'zoneId': zoneMap['Asia'],
        'location_x': 140.0,
        'location_y': 60.0,
      },
      {
        'animalName': 'Orangutan',
        'animalDetail':
            'Orangutans are the largest tree-dwelling mammals on Earth and among our closest relatives, sharing approximately '
            '97% of human DNA. Their name comes from the Malay words meaning "person of the forest." They are remarkably '
            'intelligent, using sticks as tools to extract insects and leaves as umbrellas in the rain. Orangutans spend almost '
            'their entire lives in the forest canopy and are solitary animals by nature. Mothers care for their young for up to '
            '8 years — one of the longest in the animal kingdom.',
        'animalPicture': '',
        'zoneId': zoneMap['Asia'],
        'location_x': 100.0,
        'location_y': 100.0,
      },
      {
        'animalName': 'Giant Panda',
        'animalDetail':
            'The Giant Panda is one of the world\'s most beloved and recognizable animals, serving as a global symbol of '
            'wildlife conservation. Despite being classified as carnivores, giant pandas have adapted to a diet that is 99% '
            'bamboo, consuming up to 38 kg per day to meet their energy needs. Their distinctive black-and-white coloring is '
            'thought to aid in camouflage and communication. Once critically endangered, dedicated conservation programs — '
            'particularly in China — have helped their population slowly recover, offering a hopeful story of what\'s possible '
            'when humans commit to protecting wildlife.',
        'animalPicture': '',
        'zoneId': zoneMap['Asia'],
        'location_x': 140.0,
        'location_y': 100.0,
      },
      {
        'animalName': 'Water Buffalo',
        'animalDetail':
            'The Water Buffalo is one of the most important domestic animals in Southeast Asia, having served alongside farmers '
            'for thousands of years in rice paddies and wetlands. Built with powerful, wide-spreading horns and thick, dark skin, '
            'they are superbly adapted to hot, humid climates. Water buffaloes love to wallow in mud and water, which helps '
            'regulate their body temperature and protects against insects. Their wild counterpart, the Wild Water Buffalo, is now '
            'considered endangered due to habitat loss and crossbreeding with domestic herds.',
        'animalPicture': '',
        'zoneId': zoneMap['Asia'],
        'location_x': 120.0,
        'location_y': 80.0,
      },

      // ════════════════════════════════
      // 🌍 AFRICA
      // ════════════════════════════════
      {
        'animalName': 'Giraffe',
        'animalDetail':
            'The Giraffe holds the record as the tallest living terrestrial animal on Earth, with adults reaching heights of '
            'up to 5.5 meters. Their long neck — which contains the same number of vertebrae as a human neck, just greatly '
            'elongated — allows them to browse leaves from treetops that no other land animal can reach. Despite their graceful '
            'appearance, giraffes can deliver a lethal kick and have been known to fight off lions. They sleep for only 30 minutes '
            'to 2 hours per day, often in short naps, and can go weeks without drinking water, getting moisture from the leaves they eat.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 320.0,
        'location_y': 180.0,
      },
      {
        'animalName': 'Zebra',
        'animalDetail':
            'No two zebras have the same stripe pattern — their markings are as unique as human fingerprints. Scientists believe '
            'the stripes may serve multiple purposes: confusing predators in a running herd, regulating body temperature, and even '
            'repelling biting insects. Zebras are highly social animals that live in family groups and communicate through facial '
            'expressions, ear positions, and vocalizations. They are constantly vigilant, and the herd\'s eyes are always scanning '
            'the horizon. A baby zebra can stand and run within an hour of birth — a crucial survival skill on the open savanna.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 360.0,
        'location_y': 180.0,
      },
      {
        'animalName': 'Lion',
        'animalDetail':
            'Often called the "King of Beasts," the Lion is the only truly social member of the cat family, living in structured '
            'groups called prides that can number up to 30 individuals. Males are distinguished by their impressive manes, which '
            'signal health and dominance to rivals and potential mates. Contrary to popular belief, it is the lionesses who do the '
            'majority of the hunting, working cooperatively to take down prey much larger than themselves. Lions can sleep up to '
            '20 hours a day to conserve energy in the African heat. Their roar — audible from 8 km away — is used to communicate '
            'with pride members and warn off rivals.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 320.0,
        'location_y': 220.0,
      },
      {
        'animalName': 'Hippopotamus',
        'animalDetail':
            'The Hippopotamus, despite its bulky and lumbering appearance, is considered one of the most dangerous animals in '
            'Africa. They are highly territorial in water and can run on land at speeds of up to 30 km/h for short distances. '
            'Hippos spend most of the day submerged in rivers and lakes to keep their sensitive skin cool, emerging at night to '
            'graze on grass. Their skin secretes a natural reddish fluid sometimes called "blood sweat," which acts as a '
            'moisturizer and natural sunscreen. Despite being herbivores, hippos are responsible for more human fatalities in '
            'Africa than nearly any other large animal.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 360.0,
        'location_y': 220.0,
      },
      {
        'animalName': 'Hyena',
        'animalDetail':
            'The Spotted Hyena is far more than the scavenging villain it\'s often portrayed as in popular culture. In fact, '
            'hyenas are highly skilled and coordinated hunters who kill up to 95% of their own food. They have one of the '
            'strongest bite forces of any land mammal, capable of crushing bone to access the nutritious marrow inside. Hyena '
            'societies are matriarchal — led by dominant females who are larger and stronger than males. Their iconic "laughing" '
            'call is actually a complex form of communication that conveys social status and excitement within the clan.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 340.0,
        'location_y': 200.0,
      },
      {
        'animalName': 'Gorilla',
        'animalDetail':
            'Gorillas are the largest living primates, sharing approximately 98.3% of their DNA with humans. They live in '
            'family groups of 5 to 30 individuals led by a dominant silverback male, who is responsible for protecting and '
            'guiding the group. Despite their imposing size and strength, gorillas are gentle, plant-eating animals who spend '
            'their days foraging, resting, and playing. They are capable of complex emotions, problem-solving, and even basic '
            'sign language. The famous chest-beating display is used to intimidate rivals and is a powerful warning — not a '
            'sign of aggression toward humans.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 300.0,
        'location_y': 200.0,
      },
      {
        'animalName': 'Rhinoceros',
        'animalDetail':
            'The Rhinoceros is one of the oldest groups of large mammals on Earth, a living relic of a prehistoric era. Their '
            'iconic horn is made entirely of keratin — the same protein as human fingernails — and is tragically the reason rhinos '
            'face relentless poaching pressure. A rhino\'s skin, though it looks tough as armor, is actually quite sensitive to '
            'sunburns and insect bites, which is why they love to wallow in mud. Rhinos have poor eyesight but an exceptionally '
            'keen sense of smell and hearing. Despite their size, they can sprint at up to 55 km/h — faster than most people expect.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 380.0,
        'location_y': 200.0,
      },
      {
        'animalName': 'Camel',
        'animalDetail':
            'The Dromedary Camel, with its single hump, is the supreme survivor of the Sahara Desert and one of the most '
            'uniquely adapted mammals on Earth. Contrary to popular belief, the hump does not store water — it stores fat, '
            'which can be converted to energy and water when food is scarce. A thirsty camel can drink up to 200 liters of '
            'water in a single session. Their long eyelashes, sealable nostrils, and wide padded feet are all perfectly '
            'engineered for life in the desert. For thousands of years, camels have been indispensable to desert-dwelling '
            'cultures as transport, food, and companions.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 340.0,
        'location_y': 160.0,
      },
      {
        'animalName': 'Ostrich',
        'animalDetail':
            'The Ostrich is the world\'s largest and heaviest bird, with adults weighing up to 160 kg — far too heavy to fly. '
            'What they lack in flight, they more than compensate for in speed, reaching up to 70 km/h and maintaining 50 km/h '
            'for sustained distances, making them the fastest running bird on Earth. Their powerful legs are also lethal weapons; '
            'a single kick can kill a lion. Ostriches lay the largest eggs of any living bird, with each egg weighing roughly '
            '1.5 kg. The common myth that ostriches bury their heads in sand is false — they lower their heads to turn eggs or '
            'to camouflage against predators.',
        'animalPicture': '',
        'zoneId': zoneMap['Africa'],
        'location_x': 380.0,
        'location_y': 160.0,
      },

      // ════════════════════════════════
      // 🦘 AUSTRALIA
      // ════════════════════════════════
      {
        'animalName': 'Koala',
        'animalDetail':
            'The Koala is one of Australia\'s most iconic marsupials and a beloved symbol of the country. They spend up to '
            '22 hours a day sleeping — a necessary adaptation since their diet of eucalyptus leaves is highly toxic to most '
            'mammals and provides very little energy. Koalas have a specialized digestive system to detoxify the eucalyptus '
            'compounds and are extremely selective, choosing from only a handful of the 700+ eucalyptus species. Each koala\'s '
            'nose print is as unique as a human fingerprint, and their fingerprints are virtually indistinguishable from human '
            'fingerprints — fascinating to scientists and forensic experts alike.',
        'animalPicture': '',
        'zoneId': zoneMap['Australia'],
        'location_x': 540.0,
        'location_y': 300.0,
      },
      {
        'animalName': 'Kangaroo',
        'animalDetail':
            'The Kangaroo is Australia\'s most iconic animal and a national symbol, appearing on the country\'s coat of arms. '
            'They are the world\'s largest marsupials and the only large animals that use hopping as their primary form of '
            'locomotion — a remarkably energy-efficient method at higher speeds. A female kangaroo\'s pouch is a remarkable '
            'biological incubator; a joey is born at just 2.5 cm long and crawls instinctively to the pouch where it continues '
            'developing for up to a year. Male kangaroos engage in dramatic "boxing" bouts to establish dominance. '
            'A group of kangaroos is called a mob.',
        'animalPicture': '',
        'zoneId': zoneMap['Australia'],
        'location_x': 580.0,
        'location_y': 300.0,
      },
      {
        'animalName': 'Emu',
        'animalDetail':
            'The Emu is the world\'s second-tallest bird, native to Australia, and one of only a few birds with two sets of '
            'eyelids — one for blinking and one for keeping dust out. Though they cannot fly, emus are powerful runners and '
            'strong swimmers, and they can travel great distances in search of food and water. Emus are among the rare birds '
            'where the male takes full responsibility for incubation, sitting on the eggs for nearly 60 days without eating. '
            'Australia famously lost the so-called "Emu War" of 1932, when a military campaign to control emu populations in '
            'Western Australia proved thoroughly unsuccessful.',
        'animalPicture': '',
        'zoneId': zoneMap['Australia'],
        'location_x': 540.0,
        'location_y': 340.0,
      },
      {
        'animalName': 'Wallaby',
        'animalDetail':
            'Wallabies are members of the same family as kangaroos but are generally smaller and more compact. There are dozens '
            'of wallaby species across Australia, each adapted to different habitats from rocky hillsides to dense forests. Like '
            'kangaroos, female wallabies carry their joeys in a pouch, and they have an extraordinary ability called embryonic '
            'diapause — they can pause the development of a new embryo until conditions are right for it to survive. Wallabies '
            'are herbivores, grazing on grasses and leaves, and are primarily active at dawn and dusk to avoid the midday heat.',
        'animalPicture': '',
        'zoneId': zoneMap['Australia'],
        'location_x': 580.0,
        'location_y': 340.0,
      },
      {
        'animalName': 'Quokka',
        'animalDetail':
            'The Quokka has earned global fame as the "world\'s happiest animal" thanks to the upturned shape of its mouth, '
            'which makes it look like it\'s perpetually smiling. These small marsupials are native to a few small islands off '
            'Western Australia, most famously Rottnest Island. Quokkas are remarkably unafraid of humans and are renowned for '
            'photobombing tourists with their cheerful expressions — their selfies with visitors have gone viral worldwide. '
            'Despite their cheerful appearance, quokkas are resourceful survivors who can go extended periods without water and '
            'can even re-ingest their own droppings to extract maximum nutrients.',
        'animalPicture': '',
        'zoneId': zoneMap['Australia'],
        'location_x': 560.0,
        'location_y': 320.0,
      },
      {
        'animalName': 'Cassowary',
        'animalDetail':
            'The Cassowary is one of Australia\'s most extraordinary and dangerous birds. It is the third-tallest bird in the '
            'world, can weigh up to 85 kg, and is equipped with razor-sharp claws on its inner toe that can reach 12 cm in '
            'length — capable of inflicting serious wounds. A striking blue and red neck and a bony casque on its head make it '
            'unmistakable. Despite this fearsome reputation, cassowaries play a vital ecological role as "gardeners of the '
            'rainforest," dispersing the seeds of hundreds of rainforest plant species through their droppings. They are '
            'considered a keystone species for the health of tropical rainforests.',
        'animalPicture': '',
        'zoneId': zoneMap['Australia'],
        'location_x': 600.0,
        'location_y': 320.0,
      },

      // ════════════════════════════════
      // 🌎 SOUTH AMERICA
      // ════════════════════════════════
      {
        'animalName': 'Macaw',
        'animalDetail':
            'Macaws are among the most spectacular birds on Earth, lighting up the Amazon rainforest with brilliant splashes '
            'of scarlet, cobalt, and gold. They are highly intelligent, long-lived birds — some species can live for over '
            '60 years — and form strong, lifelong pair bonds. Macaws use their powerful, hooked beaks to crack open hard nuts '
            'and seeds that few other animals can access. Their ability to mimic human speech makes them one of the most popular '
            'birds kept in captivity, though wild macaws are now threatened by deforestation and the illegal pet trade. In the '
            'wild, they gather in loud, sociable flocks at clay licks to absorb essential minerals.',
        'animalPicture': '',
        'zoneId': zoneMap['South America'],
        'location_x': 180.0,
        'location_y': 400.0,
      },
      {
        'animalName': 'Jaguar',
        'animalDetail':
            'The Jaguar is the largest big cat in the Americas and the third-largest cat in the world, ranking behind only '
            'lions and tigers. Unlike many other large cats, jaguars are strong swimmers and actively seek out rivers and '
            'wetlands, often hunting caimans, capybaras, and even anacondas. Their rosette-spotted coat provides exceptional '
            'camouflage in the dappled light of the rainforest. Jaguars have the most powerful bite force relative to skull '
            'size of any big cat — strong enough to pierce turtle shells. In many indigenous cultures of the Americas, the '
            'jaguar is revered as a symbol of power, night, and the underworld.',
        'animalPicture': '',
        'zoneId': zoneMap['South America'],
        'location_x': 220.0,
        'location_y': 400.0,
      },
      {
        'animalName': 'Sloth',
        'animalDetail':
            'The Sloth is the slowest mammal on Earth and has turned slowness into a masterpiece of survival. Moving at an '
            'average speed of just 0.24 km/h, sloths conserve so much energy that they only need to descend from their trees '
            'to defecate once a week. Their fur grows in the opposite direction from most mammals — from belly to back — to '
            'shed rain while hanging upside down. A unique ecosystem lives in a sloth\'s fur: algae, moths, beetles, and fungi, '
            'which help camouflage the sloth against predators. Despite their lethargy, sloths are surprisingly strong swimmers '
            'and can hold their breath for up to 40 minutes by slowing their heart rate.',
        'animalPicture': '',
        'zoneId': zoneMap['South America'],
        'location_x': 180.0,
        'location_y': 440.0,
      },
      {
        'animalName': 'Alpaca',
        'animalDetail':
            'The Alpaca is a domesticated South American camelid that has been raised for thousands of years by Andean '
            'civilizations for its extraordinarily soft and warm fleece. Living at altitudes of up to 4,800 meters in the '
            'Andes mountains, alpacas are perfectly adapted to cold, thin-air environments. Their fiber is naturally '
            'hypoallergenic, containing no lanolin, and comes in 22 natural color variations — more than any other '
            'fiber-producing animal. Alpacas are calm, social herd animals that communicate through humming sounds and body '
            'language. Unlike llamas, they are too small to be used as pack animals and are raised primarily for their fiber '
            'and as companion animals.',
        'animalPicture': '',
        'zoneId': zoneMap['South America'],
        'location_x': 220.0,
        'location_y': 440.0,
      },
      {
        'animalName': 'Squirrel Monkey',
        'animalDetail':
            'Squirrel Monkeys are among the most agile and social primates of the Amazon, living in troops that can number '
            'up to 500 individuals — one of the largest primate groups of any species. Despite their small size (typically '
            'under 1 kg), they are bold and inquisitive, racing through the rainforest canopy in search of fruit, insects, '
            'and small vertebrates. Squirrel monkeys have the largest brain-to-body size ratio of any primate — even larger '
            'than humans. Females form the core social structure of the group, while males gather only during mating season. '
            'Their distinctive white-and-black facial markings make them one of the most charming residents of the jungle.',
        'animalPicture': '',
        'zoneId': zoneMap['South America'],
        'location_x': 200.0,
        'location_y': 420.0,
      },
      {
        'animalName': 'Green Anaconda',
        'animalDetail':
            'The Green Anaconda is the heaviest snake in the world and one of the longest, with some individuals exceeding '
            '8 meters in length and weighing over 200 kg. Despite its massive size, the anaconda is a stealthy, semi-aquatic '
            'predator that uses the murky rivers and swamps of the Amazon basin to ambush prey. It is a constrictor — it kills '
            'by squeezing its prey until its heart stops, then swallows it whole. Anacondas can consume animals as large as '
            'deer, caimans, and even jaguars on rare occasions. After a large meal, an anaconda may not need to eat again for '
            'weeks or even months. Female anacondas are significantly larger than males.',
        'animalPicture': '',
        'zoneId': zoneMap['South America'],
        'location_x': 200.0,
        'location_y': 460.0,
      },

      // ════════════════════════════════
      // ❄️ FREEZING
      // ════════════════════════════════
      {
        'animalName': 'Penguin',
        'animalDetail':
            'Penguins are flightless seabirds perfectly engineered for life in and around the coldest oceans on Earth. Their '
            'wings have evolved into powerful flippers, and underwater they are breathtaking athletes — rockhopper and gentoo '
            'penguins can swim at up to 36 km/h and dive to depths exceeding 500 meters. Their tuxedo-like black-and-white '
            'coloring is actually a form of camouflage called countershading: dark from above to blend with the ocean depths, '
            'light from below to blend with the bright surface. Emperor penguin fathers endure the brutal Antarctic winter for '
            '65 days, balancing a single egg on their feet, eating nothing, in temperatures as low as -60°C.',
        'animalPicture': '',
        'zoneId': zoneMap['Freezing'],
        'location_x': 460.0,
        'location_y': 60.0,
      },
      {
        'animalName': 'Polar Bear',
        'animalDetail':
            'The Polar Bear is the world\'s largest land carnivore and the undisputed master of the Arctic. A fully grown '
            'male can weigh over 700 kg and measure more than 3 meters from nose to tail. Despite appearing white, polar bear '
            'fur is actually transparent and hollow, capturing heat from sunlight and conducting it to their jet-black skin '
            'beneath. They are extraordinary swimmers, capable of covering 60 km in open water without resting, using their '
            'enormous front paws as paddles. Polar bears are almost entirely carnivorous, depending on ringed seals for most '
            'of their diet. As Arctic sea ice declines due to climate change, polar bears face an increasingly uncertain future.',
        'animalPicture': '',
        'zoneId': zoneMap['Freezing'],
        'location_x': 500.0,
        'location_y': 60.0,
      },
      {
        'animalName': 'Moose',
        'animalDetail':
            'The Moose is the largest member of the deer family, with bulls standing up to 2.1 meters at the shoulder and '
            'bearing enormous, palmate antlers that can span over 1.8 meters across. Despite their ungainly appearance, moose '
            'are powerful swimmers and can submerge themselves completely to feed on aquatic plants, staying underwater for up '
            'to 50 seconds. In winter, they use their long legs to wade through deep snow that would stop most other animals. '
            'Moose are generally solitary and can be unexpectedly aggressive — they injure more people in North America each '
            'year than bears do. Bulls shed and regrow their massive antlers every single year.',
        'animalPicture': '',
        'zoneId': zoneMap['Freezing'],
        'location_x': 460.0,
        'location_y': 100.0,
      },
      {
        'animalName': 'Brown Bear',
        'animalDetail':
            'The Brown Bear is one of the most widely distributed large carnivores on Earth, found across North America, '
            'Europe, and Asia. Subspecies include the famous Grizzly Bear of North America. Despite being classified as '
            'carnivores, brown bears are highly omnivorous — in summer and autumn, up to 90% of their diet consists of berries, '
            'nuts, and plants as they enter hyperphagia, consuming up to 20,000 calories per day to build fat reserves for '
            'winter. Their sense of smell is estimated to be 2,100 times more powerful than that of humans. Brown bears do '
            'not truly hibernate — they enter a state called torpor, in which their heart rate slows and they do not eat, '
            'drink, or produce waste for months.',
        'animalPicture': '',
        'zoneId': zoneMap['Freezing'],
        'location_x': 500.0,
        'location_y': 100.0,
      },
    ];

    for (var animal in animals) {
      await _db.collection('animal').add(animal);
      print('Added animal: ${animal['animalName']}');
    }
  }
}