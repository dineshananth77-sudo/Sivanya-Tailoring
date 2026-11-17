class MockFashionData {
  // Horizontal Category Avatars (Meesho-style circular categories)
  static final List<Map<String, String>> categories = [
    {
      'name': 'Sarees',
      'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=300',
    },
    {
      'name': 'Kurtis',
      'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=300',
    },
    {
      'name': 'Blouses',
      'image': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300',
    },
    {
      'name': 'Lehengas',
      'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=300',
    },
    {
      'name': 'Dresses',
      'image': 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=300',
    },
    {
      'name': 'Salwar Suits',
      'image': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=300',
    },
    {
      'name': 'Anarkali Suits',
      'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=300',
    },
    {
      'name': 'Gowns',
      'image': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=300',
    },
    {
      'name': 'Palazzo Sets',
      'image': 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=300',
    },
    {
      'name': 'Sharara Sets',
      'image': 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=300',
    },
    {
      'name': 'Chudidars',
      'image': 'https://images.unsplash.com/photo-1583391733975-067dd724c94b?w=300',
    },
    {
      'name': 'Half Sarees',
      'image': 'https://images.unsplash.com/photo-1610030469668-9655ec1f0842?w=300',
    },
    {
      'name': 'Ethnic Wear',
      'image': 'https://images.unsplash.com/photo-1502716119720-b23a93e5fe1b?w=300',
    },
    {
      'name': 'Party Wear',
      'image': 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=300',
    },
    {
      'name': 'Bridal Wear',
      'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=300',
    },
    {
      'name': 'Co-ord Sets',
      'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300',
    },
    {
      'name': 'Skirts & Tops',
      'image': 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=300',
    },
    {
      'name': 'Tunics',
      'image': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=300',
    },
    {
      'name': 'Custom Stitching',
      'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=300',
    },
  ];

  // Promotional Banners Carousel
  static final List<Map<String, String>> banners = [
    {
      'title': 'DISCOVER YOUR PERFECT FIT',
      'subtitle': 'Bespoke Designer Blouses & Ethnic Wear',
      'tag': 'FESTIVE SPECIAL',
      'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=1000',
    },
    {
      'title': 'CUSTOM STITCHING MADE EASY',
      'subtitle': 'Send measurements or upload your design',
      'tag': 'DOORSTEP TAILORING',
      'image': 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=1000',
    },
    {
      'title': 'ROYAL BRIDAL LEHENGAS',
      'subtitle': 'Handcrafted embroidery & pure fabrics',
      'tag': 'WEDDING COLLECTION',
      'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=1000',
    },
    {
      'title': 'EVERYDAY CHIC KURTIS',
      'subtitle': 'Comfortable cotton & festive silks',
      'tag': 'NEW ARRIVALS',
      'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1000',
    },
    {
      'title': 'DREAM BRIDAL WEAR',
      'subtitle': 'Exquisite gowns, lehengas & sarees for your big day',
      'tag': 'BRIDAL COLLECTION',
      'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=1000',
    },
  ];

  // Rich Fashion Catalogue Products (30+ items)
  static final List<Map<String, dynamic>> products = [
    // --- Sarees ---
    {
      'title': 'Kanchipuram Silk Bridal Saree',
      'category': 'Sarees',
      'price': '₹1,499',
      'originalPrice': '₹2,999',
      'discount': '50% off',
      'rating': '4.5',
      'reviews': '418',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600',
      'description':
          'Traditional rich weave with contrast pallu and unstitched blouse piece. Tailoring consultation available.',
    },
    {
      'title': 'Banarasi Georgette Print Saree',
      'category': 'Sarees',
      'price': '₹899',
      'originalPrice': '₹1,799',
      'discount': '50% off',
      'rating': '4.3',
      'reviews': '224',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1476234251651-f353703a034d?w=600',
      'description':
          'Lightweight georgette saree with intricate Banarasi motifs. Comes with matching blouse piece.',
    },

    // --- Kurtis ---
    {
      'title': 'Anarkali Festive Kurti Set',
      'category': 'Kurtis',
      'price': '₹799',
      'originalPrice': '₹1,599',
      'discount': '50% off',
      'rating': '4.2',
      'reviews': '189',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600',
      'description':
          'Flared floral cotton Anarkali with dupatta and matching trousers. Tailored to your exact size.',
    },
    {
      'title': 'Printed Cotton Straight Kurti',
      'category': 'Kurtis',
      'price': '₹399',
      'originalPrice': '₹799',
      'discount': '50% off',
      'rating': '4.0',
      'reviews': '310',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=600',
      'description':
          'Breathable pure cotton kurti with block print design. Perfect for daily wear and casual outings.',
    },

    // --- Blouses ---
    {
      'title': 'Gold Embroidered Silk Blouse',
      'category': 'Blouses',
      'price': '₹599',
      'originalPrice': '₹1,299',
      'discount': '53% off',
      'rating': '4.3',
      'reviews': '256',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600',
      'description':
          'Handcrafted premium padded blouse with intricate zari embroidery. Perfectly lined with pure cotton for comfort.',
    },
    {
      'title': 'Backless Mirror Work Blouse',
      'category': 'Blouses',
      'price': '₹499',
      'originalPrice': '₹999',
      'discount': '50% off',
      'rating': '4.1',
      'reviews': '132',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1521334884684-d80222895322?w=600',
      'description':
          'Trendy backless blouse adorned with Rajasthani mirror work. Fully customisable neck and sleeve style.',
    },

    // --- Lehengas ---
    {
      'title': 'Velvet Embroidered Bridal Lehenga',
      'category': 'Lehengas',
      'price': '₹2,999',
      'originalPrice': '₹6,499',
      'discount': '54% off',
      'rating': '4.7',
      'reviews': '532',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600',
      'description':
          'Heavily worked semi-stitched bridal lehenga with custom blouse stitching option.',
    },
    {
      'title': 'Floral Georgette Party Lehenga',
      'category': 'Lehengas',
      'price': '₹1,799',
      'originalPrice': '₹3,599',
      'discount': '50% off',
      'rating': '4.4',
      'reviews': '198',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1543087903-1ac2364bab84?w=600',
      'description':
          'Vibrant floral lehenga with thread and sequence embroidery. Ideal for sangeet and mehendi functions.',
    },

    // --- Dresses ---
    {
      'title': 'Flared Georgette Evening Dress',
      'category': 'Dresses',
      'price': '₹999',
      'originalPrice': '₹1,899',
      'discount': '47% off',
      'rating': '4.1',
      'reviews': '98',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=600',
      'description':
          'Breezy layered maxi dress with delicate embroidery on the neckline.',
    },
    {
      'title': 'Midi Wrap Casual Dress',
      'category': 'Dresses',
      'price': '₹699',
      'originalPrice': '₹1,299',
      'discount': '46% off',
      'rating': '3.9',
      'reviews': '75',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=600',
      'description':
          'Comfortable wrap-style midi dress in breathable viscose fabric. Great for brunch and day outings.',
    },

    // --- Salwar Suits ---
    {
      'title': 'Chanderi Silk Salwar Suit',
      'category': 'Salwar Suits',
      'price': '₹1,199',
      'originalPrice': '₹2,299',
      'discount': '48% off',
      'rating': '4.4',
      'reviews': '310',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600',
      'description':
          'Classic Chanderi 3-piece unstitched suit material with custom stitching support.',
    },

    // --- Anarkali Suits ---
    {
      'title': 'Heavy Embroidered Anarkali Suit',
      'category': 'Anarkali Suits',
      'price': '₹1,599',
      'originalPrice': '₹3,199',
      'discount': '50% off',
      'rating': '4.5',
      'reviews': '267',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600',
      'description':
          'Floor-length Anarkali suit with heavy sequin and thread embroidery. Includes dupatta and churidar.',
    },

    // --- Gowns ---
    {
      'title': 'Net Embellished Party Gown',
      'category': 'Gowns',
      'price': '₹2,499',
      'originalPrice': '₹4,999',
      'discount': '50% off',
      'rating': '4.6',
      'reviews': '342',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=600',
      'description':
          'Stunning full-length net gown with stone embellishments. Perfect for receptions and gala events.',
    },
    {
      'title': 'Floral Printed Maxi Gown',
      'category': 'Gowns',
      'price': '₹1,299',
      'originalPrice': '₹2,599',
      'discount': '50% off',
      'rating': '4.2',
      'reviews': '154',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1529139574466-a303027614b2?w=600',
      'description':
          'Flowy maxi gown in floral chiffon fabric. Backless design with adjustable tie-up back.',
    },

    // --- Palazzo Sets ---
    {
      'title': 'Printed Rayon Palazzo Set',
      'category': 'Palazzo Sets',
      'price': '₹699',
      'originalPrice': '₹1,399',
      'discount': '50% off',
      'rating': '4.1',
      'reviews': '187',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1562572159-4eaece6e3e3c?w=600',
      'description':
          'Comfortable wide-leg palazzo paired with a matching kurti top. Great for casual and festive wear.',
    },

    // --- Sharara Sets ---
    {
      'title': 'Embroidered Sharara Set',
      'category': 'Sharara Sets',
      'price': '₹1,899',
      'originalPrice': '₹3,799',
      'discount': '50% off',
      'rating': '4.5',
      'reviews': '223',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1536766820879-059fec98ec0a?w=600',
      'description':
          'Flared sharara set with thread embroidery and matching dupatta. Ideal for weddings and festivals.',
    },

    // --- Chudidars ---
    {
      'title': 'Cotton Churidar Salwar Set',
      'category': 'Chudidars',
      'price': '₹599',
      'originalPrice': '₹1,199',
      'discount': '50% off',
      'rating': '4.0',
      'reviews': '143',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1467043237213-65f2da53396f?w=600',
      'description':
          'Classic cotton churidar suit with block print kurta and matching dupatta. Tailored to custom size.',
    },

    // --- Half Sarees ---
    {
      'title': 'South Indian Silk Half Saree',
      'category': 'Half Sarees',
      'price': '₹1,299',
      'originalPrice': '₹2,599',
      'discount': '50% off',
      'rating': '4.4',
      'reviews': '176',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1468971050039-be99497410af?w=600',
      'description':
          'Traditional Langa Voni (half saree) set in pure silk with golden zari border. Perfect for festivals.',
    },

    // --- Ethnic Wear ---
    {
      'title': 'Ikkat Print Ethnic Kurti Pant Set',
      'category': 'Ethnic Wear',
      'price': '₹899',
      'originalPrice': '₹1,799',
      'discount': '50% off',
      'rating': '4.2',
      'reviews': '211',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600',
      'description':
          'Handwoven Ikkat print ethnic set with comfortable pant and matching dupatta.',
    },

    // --- Party Wear ---
    {
      'title': 'Sequin Embellished Party Kurta',
      'category': 'Party Wear',
      'price': '₹1,499',
      'originalPrice': '₹2,999',
      'discount': '50% off',
      'rating': '4.5',
      'reviews': '289',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600',
      'description':
          'Glamorous all-over sequin kurta with side slits and V-neckline. Pairs perfectly with palazzos.',
    },

    // --- Bridal Wear ---
    {
      'title': 'Royal Bridal Lehenga & Dupatta Set',
      'category': 'Bridal Wear',
      'price': '₹4,999',
      'originalPrice': '₹9,999',
      'discount': '50% off',
      'rating': '4.8',
      'reviews': '621',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=600',
      'description':
          'Exquisite bridal lehenga with hand embroidered zardosi and kundan work. Complete with dupatta and blouse.',
    },

    // --- Co-ord Sets ---
    {
      'title': 'Pastel Tie-Dye Co-ord Set',
      'category': 'Co-ord Sets',
      'price': '₹799',
      'originalPrice': '₹1,599',
      'discount': '50% off',
      'rating': '4.1',
      'reviews': '118',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=600',
      'description':
          'Matching tie-dye crop top and wide-leg trousers in soft cotton. Trendy co-ord set for casual outings.',
    },

    // --- Skirts & Tops ---
    {
      'title': 'Floral Skirt & Lace Top Set',
      'category': 'Skirts & Tops',
      'price': '₹699',
      'originalPrice': '₹1,399',
      'discount': '50% off',
      'rating': '3.9',
      'reviews': '89',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=600',
      'description':
          'Flowy floral midi skirt with matching lace top. Perfect for brunches and casual celebrations.',
    },
    {
      'title': 'High-Waist A-Line Skirt & Tie Top',
      'category': 'Skirts & Tops',
      'price': '₹599',
      'originalPrice': '₹1,199',
      'discount': '50% off',
      'rating': '4.0',
      'reviews': '102',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1476234251651-f353703a034d?w=600',
      'description':
          'Elegant high-waist A-line skirt paired with a knot-front tie top in complementary shades.',
    },

    // --- Tunics ---
    {
      'title': 'Embroidered Neck Tunic Dress',
      'category': 'Tunics',
      'price': '₹499',
      'originalPrice': '₹999',
      'discount': '50% off',
      'rating': '4.0',
      'reviews': '134',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1529139574466-a303027614b2?w=600',
      'description':
          'Long tunic with intricate embroidery at neckline and sleeves. Can be worn as a dress or over leggings.',
    },

    // --- Palazzo Sets (Printed & Flared) ---
    {
      'title': 'Printed Rayon Flared Palazzo Set',
      'category': 'Palazzo Sets',
      'price': '₹899',
      'originalPrice': '₹1,799',
      'discount': '50% off',
      'rating': '4.4',
      'reviews': '142',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
      'description':
          'Comfortable breathable rayon printed kurta paired with flared wide-leg palazzo pants.',
    },

    // --- Half Sarees (Festive) ---
    {
      'title': 'Traditional South Silk Half Saree',
      'category': 'Half Sarees',
      'price': '₹2,499',
      'originalPrice': '₹4,999',
      'discount': '50% off',
      'rating': '4.6',
      'reviews': '84',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1610030469668-9655ec1f0842?w=600',
      'description':
          'Traditional South Indian Dhavani half saree set with heavy zari work border and contrast blouse.',
    },

    // --- Custom Stitching ---
    {
      'title': 'Custom Blouse Stitching Service',
      'category': 'Custom Stitching',
      'price': '₹299',
      'originalPrice': '₹599',
      'discount': '50% off',
      'rating': '4.7',
      'reviews': '509',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=600',
      'description':
          'Expert blouse stitching with over 20 sleeve and neck style options. Send your fabric and measurements.',
    },
    {
      'title': 'Full Suit Custom Tailoring',
      'category': 'Custom Stitching',
      'price': '₹699',
      'originalPrice': '₹1,399',
      'discount': '50% off',
      'rating': '4.6',
      'reviews': '374',
      'freeDelivery': false,
      'image': 'https://images.unsplash.com/photo-1543087903-1ac2364bab84?w=600',
      'description':
          'Complete salwar suit stitching from your fabric. Upload design reference or choose from 50+ templates.',
    },

    // --- Sharara Sets (Party Wear) ---
    {
      'title': 'Embroidered Peplum Sharara Set',
      'category': 'Sharara Sets',
      'price': '₹1,699',
      'originalPrice': '₹3,399',
      'discount': '50% off',
      'rating': '4.5',
      'reviews': '216',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=600',
      'description':
          'Georgette peplum top with mirror work accents and multi-layered tiered sharara pants.',
    },
    // --- Chudidars (Classic Tailored) ---
    {
      'title': 'Pure Tussar Silk Chudidar Suit',
      'category': 'Chudidars',
      'price': '₹1,499',
      'originalPrice': '₹2,999',
      'discount': '50% off',
      'rating': '4.3',
      'reviews': '178',
      'freeDelivery': true,
      'image': 'https://images.unsplash.com/photo-1583391733975-067dd724c94b?w=600',
      'description':
          'Classic tailored Tussar silk kameez paired with form-fitting chudidar and chiffon dupatta.',
    },
  ];

  // Shop By Category Highlights
  static final List<Map<String, String>> shopByCategory = [
    {
      'name': 'Traditional Sarees',
      'category': 'Sarees',
      'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=500',
      'discount': 'Up to 60% Off',
    },
    {
      'name': 'Designer Blouses',
      'category': 'Blouses',
      'image': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=500',
      'discount': 'From ₹499',
    },
    {
      'name': 'Festive Kurtis',
      'category': 'Kurtis',
      'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=500',
      'discount': 'Starting ₹399',
    },
    {
      'name': 'Party Lehengas',
      'category': 'Lehengas',
      'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=500',
      'discount': 'Min 40% Off',
    },
    {
      'name': 'Bridal Wear',
      'category': 'Bridal Wear',
      'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=500',
      'discount': 'Up to 50% Off',
    },
    {
      'name': 'Anarkali Suits',
      'category': 'Anarkali Suits',
      'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=500',
      'discount': 'From ₹999',
    },
    {
      'name': 'Custom Stitching',
      'category': 'Custom Stitching',
      'image': 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=500',
      'discount': 'Starting ₹299',
    },
    {
      'name': 'Party Wear Gowns',
      'category': 'Gowns',
      'image': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=500',
      'discount': 'Up to 55% Off',
    },
  ];
}
