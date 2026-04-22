//อันนี้เอาไว้เพิ่มข้อมูลทีเดียวลง firebase จะลบก็ได้ไม่มีผล


import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAll() async {
  print('🌱 Starting seed...');
  
  // Seed zones ก่อน แล้ว print ให้เห็นว่ามีกี่ zone
  await _seedZones();
  
  // เช็คก่อนว่า zone มีจริง
  final check = await _db.collection('zone').get();
  print('✅ Zones in DB: ${check.docs.length}');
  for (var doc in check.docs) {
    print('Zone found: ${(doc.data())['zoneName']}');
  }
  
  await _seedAnimals();
  print('✅ Seed completed!');
}

  Future<void> _seedZones() async {
    final zones = [
      {'zoneName': 'Asia'},
      {'zoneName': 'Africa'},
      {'zoneName': 'Australia'},
      {'zoneName': 'South America'},
      {'zoneName': 'Freezing'},
    ];
  }

  Future<void> _seedAnimals() async {
    final zoneSnap = await _db.collection('zone').get();
    final zoneMap = {
      for (var doc in zoneSnap.docs)
        (doc.data() as Map<String, dynamic>)['zoneName'] as String:
            doc.reference,
    };

    final animals = [
      // 🌏 Asia
      {
        'animalName': 'Asian Elephant',
        'animalDetail':
            'The largest land animal in Asia, known for its smaller ears compared to African elephants.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Asia'],
      },
      {
        'animalName': 'Tiger',
        'animalDetail':
            'Specifically the Bengal Tiger or Indochine Tiger, they are the kings of the Asian jungle.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Asia'],
      },
      {
        'animalName': 'Orangutan',
        'animalDetail':
            'Great apes found in Indonesia and Malaysia; their name means "person of the forest."',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Asia'],
      },
      {
        'animalName': 'Giant Panda',
        'animalDetail':
            'China\'s national treasure, famous for eating bamboo almost exclusively.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Asia'],
      },
      {
        'animalName': 'Water Buffalo',
        'animalDetail':
            'A domestic and wild bovine often seen in the wetlands and rice paddies of Southeast Asia.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Asia'],
      },

      // 🌍 Africa
      {
        'animalName': 'Giraffe',
        'animalDetail':
            'The tallest land animal in the world with a neck that can reach up to 2 meters.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Zebra',
        'animalDetail':
            'Known for its unique black-and-white striped coat, which acts as a natural camouflage.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Lion',
        'animalDetail':
            'Known as the "King of Beasts," living in social groups called prides.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Hippopotamus',
        'animalDetail':
            'A large, semi-aquatic mammal that is surprisingly fast and very territorial.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Hyena',
        'animalDetail':
            'Famous for its "laughing" call and being a highly skilled scavenger and hunter.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Gorilla',
        'animalDetail':
            'The largest living primate, inhabiting the tropical forests of equatorial Africa.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Rhinoceros',
        'animalDetail':
            'Characterized by its thick skin and horns; a member of the "Big Five" safari animals.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Camel',
        'animalDetail':
            'The one-humped camel adapted to the harsh heat of the Sahara Desert.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },
      {
        'animalName': 'Ostrich',
        'animalDetail':
            'The world\'s largest and heaviest bird; it cannot fly but can run incredibly fast.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Africa'],
      },

      // 🦘 Australia
      {
        'animalName': 'Koala',
        'animalDetail':
            'An arboreal herbivorous marsupial that feeds almost entirely on eucalyptus leaves.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Australia'],
      },
      {
        'animalName': 'Kangaroo',
        'animalDetail':
            'The symbol of Australia, known for hopping on powerful hind legs and carrying young in pouches.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Australia'],
      },
      {
        'animalName': 'Emu',
        'animalDetail':
            'A large, flightless bird, second in height only to the ostrich.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Australia'],
      },
      {
        'animalName': 'Wallaby',
        'animalDetail':
            'Very similar to kangaroos but generally smaller in size.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Australia'],
      },
      {
        'animalName': 'Quokka',
        'animalDetail':
            'Famous as the "world\'s happiest animal" because of its constant smiling expression.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Australia'],
      },
      {
        'animalName': 'Cassowary',
        'animalDetail':
            'A large, flightless bird with a blue neck and a "helmet" on its head; it can be quite dangerous!',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Australia'],
      },

      // 🌎 South America
      {
        'animalName': 'Macaw',
        'animalDetail':
            'Large, colorful parrots found in the Amazon rainforest.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['South America'],
      },
      {
        'animalName': 'Jaguar',
        'animalDetail':
            'The largest cat species in the Americas, known for having the strongest bite force.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['South America'],
      },
      {
        'animalName': 'Sloth',
        'animalDetail':
            'A slow-moving mammal that spends most of its life hanging upside down in trees.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['South America'],
      },
      {
        'animalName': 'Alpaca',
        'animalDetail':
            'A domesticated species of South American camelid, prized for its soft wool.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['South America'],
      },
      {
        'animalName': 'Squirrel Monkey',
        'animalDetail':
            'Small, agile monkeys that live in the canopy of the tropical rainforests.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['South America'],
      },
      {
        'animalName': 'Green Anaconda',
        'animalDetail':
            'One of the longest and heaviest snakes in the world, found in the Amazon basin.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['South America'],
      },

      // ❄️ Freezing
      {
        'animalName': 'Penguin',
        'animalDetail':
            'Flightless seabirds that live almost exclusively in the Southern Hemisphere (Antarctica).',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Freezing'],
      },
      {
        'animalName': 'Polar Bear',
        'animalDetail':
            'The world\'s largest land carnivore, perfectly adapted to the Arctic ice.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Freezing'],
      },
      {
        'animalName': 'Moose',
        'animalDetail':
            'The largest species in the deer family, easily recognized by their massive palmate antlers.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Freezing'],
      },
      {
        'animalName': 'Brown Bear',
        'animalDetail':
            'Includes subspecies like the Grizzly Bear, found across North America and Eurasia.',
        'animalPicture': 'URL',
        'zoneId': zoneMap['Freezing'],
      },
    ];

    for (var animal in animals) {
      await _db.collection('animal').add(animal);
      print('Added animal: ${animal['animalName']}');
    }
  }
}
