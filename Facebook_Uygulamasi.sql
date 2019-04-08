CREATE DATABASE Facebook_Uygulamasi;

USE Facebook_Uygulamasi;

CREATE TABLE `Facebook_Uygulamasi`.`users` (
  `user_id` INT UNSIGNED NOT NULL,
  `fname` VARCHAR(256) NOT NULL,
  `lname` VARCHAR(256) NOT NULL,
  `Born_date` date  NOT NULL,
  `sex` VARCHAR(256) NOT NULL,
  `password` VARCHAR(256) NOT NULL,
  `language` VARCHAR(256) NOT NULL,
  `email` VARCHAR(256) NOT NULL,
   CONSTRAINT `unique_users` UNIQUE (`email`),
   PRIMARY KEY (`user_id`),
   CONSTRAINT `languageFK` FOREIGN KEY (`language`)
   REFERENCES diller(`dil`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);

CREATE TABLE `Facebook_Uygulamasi`.`diller` (
  `dil` VARCHAR(256) NOT NULL,
  PRIMARY KEY (`dil`)
);

CREATE TABLE `Facebook_Uygulamasi`.`profil` (
  `profil_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `biografi` VARCHAR(256),
  `yasadigi_yer` VARCHAR(256) NOT NULL,
  `memleket` VARCHAR(256) NOT NULL,
   CONSTRAINT `unique_users` UNIQUE (`user_id`),
   PRIMARY KEY (`profil_id`),
   CONSTRAINT `profil_user_idFK` FOREIGN KEY (`user_id`)
   REFERENCES users(`user_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE,
   CONSTRAINT `yasadigi_yerFK` FOREIGN KEY (`yasadigi_yer`)
   REFERENCES Sehir_Ulke(`sehir_ulke`)
   ON DELETE CASCADE
   ON UPDATE CASCADE,
   CONSTRAINT `memleketFK` FOREIGN KEY (`memleket`)
   REFERENCES Sehir_Ulke(`sehir_ulke`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);

CREATE TABLE `Facebook_Uygulamasi`.`Sehir_Ulke` (
  `sehir_ulke` VARCHAR(256) NOT NULL,
  PRIMARY KEY (`sehir_ulke`)
);

CREATE TABLE `Facebook_Uygulamasi`.`egitim` (
  `profil_id` INT UNSIGNED NOT NULL,
  `okul` VARCHAR(256) NOT NULL,
  `basladıgı_tarih` date  NOT NULL,
  `bitirdigi_tarih` date  NOT NULL,
  `acıklama` VARCHAR(256) ,
  `bolum` VARCHAR(256) ,
   CONSTRAINT `profilFK` FOREIGN KEY (`profil_id`)
   REFERENCES profil(`profil_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);

CREATE TABLE `Facebook_Uygulamasi`.`calistigi_yerler` (
  `profil_id` INT UNSIGNED NOT NULL,
  `sirket_adi` VARCHAR(256) NOT NULL,
  `pozisyon` VARCHAR(256) NOT NULL,
  `basladıgı_tarih` date  NOT NULL,
  `acıklama` VARCHAR(256) ,
   CONSTRAINT `profil_yerlerFK` FOREIGN KEY (`profil_id`)
   REFERENCES profil(`profil_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);


CREATE TABLE `Facebook_Uygulamasi`.`ayarlar` (
  `user_id` INT UNSIGNED NOT NULL,
  `arkadas_listesi_gizli_mi` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `paylasimlar_gizli_mi` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `takip_ettigin_sayfalari_kim_gorebilir` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `etiketlenen_gonderileri_kimler_gorebilir` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  CONSTRAINT `unique_ayarlar` UNIQUE (`user_id`),
  CONSTRAINT `ayarlar_user_idFK` FOREIGN KEY (`user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE  `Facebook_Uygulamasi`.`friends` 
( 
  `istek_gonderen_user_id` INT(10) UNSIGNED NOT NULL,
  `istegi_alan_user_id` INT(10) UNSIGNED NOT NULL,
  `arkadaslik_durumu` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  CONSTRAINT `unique_friends` UNIQUE (`istek_gonderen_user_id`,`istegi_alan_user_id`),
  CONSTRAINT `action_user_idFK` FOREIGN KEY (`istek_gonderen_user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT `other_user_idFK` FOREIGN KEY (`istegi_alan_user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER insertfriends BEFORE INSERT
ON friends
FOR EACH ROW
BEGIN
   IF (new.istek_gonderen_user_id = new.istegi_alan_user_id) 
   THEN
   signal sqlstate '45000' set message_text="iki kullanıcı aynıdır";
   END IF;
   
   if exists(select istegi_alan_user_id,istek_gonderen_user_id,arkadaslik_durumu from friends 
   where new.istek_gonderen_user_id=istegi_alan_user_id and new.istegi_alan_user_id=istek_gonderen_user_id)
   then
   signal sqlstate '45000' set message_text="bu kayıt daha onceden eklenmis";
   END IF;
   
   
END//
DELIMITER ;

DROP TRIGGER insertfriends;


CREATE TABLE  `Facebook_Uygulamasi`.`message` 
( 
  `alici_user_id` INT(10) UNSIGNED NOT NULL,
  `gonderici_user_id` INT(10) UNSIGNED NOT NULL,
  `spam_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `archived_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `unread_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `icerik` VARCHAR(256) NOT NULL,
  `mesaj_turu` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  CONSTRAINT `alici_user_idFK` FOREIGN KEY (`alici_user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT `gonderici_user_idFK` FOREIGN KEY (`gonderici_user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER messages BEFORE INSERT
ON message
FOR EACH ROW
BEGIN
   IF (new.mesaj_turu=0)  THEN 
     if exists(select istegi_alan_user_id,istek_gonderen_user_id  from facebook_uygulamasi.friends 
               where ((friends.istek_gonderen_user_id = new.alici_user_id or
                      friends.istegi_alan_user_id = new.alici_user_id) and 
                      (friends.istek_gonderen_user_id = new.gonderici_user_id or
                      friends.istegi_alan_user_id = new.gonderici_user_id)  and 
                      friends.arkadaslik_durumu=3)) then
        signal sqlstate '45000' set message_text=" engelli kullanıcı,mesaj gönderemezsiniz";
     end if;
   END IF;
   
   IF (new.mesaj_turu=1)  THEN 
     if not exists(select kurucu_user_id from facebook_uygulamasi.pages where  (kurucu_user_id = new.alici_user_id)) then
        signal sqlstate '45000' set message_text=" mesajı alan kayıtlı sayfa admini yok";
     end if;
   END IF;
   
   IF (new.mesaj_turu=2)  THEN 
     if not exists(select kurucu_user_id from facebook_uygulamasi.social_groups where (kurucu_user_id = new.alici_user_id)) then
        signal sqlstate '45000' set message_text=" mesajı alan kayıtlı grup admini yok";
     end if;
   END IF;
   
END//
DELIMITER ;

DROP TRIGGER messages;

CREATE TABLE  `Facebook_Uygulamasi`.`pages` 
( 
  `page_id` INT(10) UNSIGNED NOT NULL,
  `kurucu_user_id` INT(10) UNSIGNED NOT NULL,
  `page_name` VARCHAR(256) NOT NULL,
  `hakkında` VARCHAR(256) NOT NULL,
   PRIMARY KEY (`page_id`),
   CONSTRAINT `unique_pages` UNIQUE (kurucu_user_id,page_name),
   CONSTRAINT `kurucu_user_idFK` FOREIGN KEY (`kurucu_user_id`)
   REFERENCES users(`user_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);



CREATE TABLE  `Facebook_Uygulamasi`.`sayfa_takipcileri` 
( 
  `page_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
   CONSTRAINT `unique_followed_pages` UNIQUE (`page_id`,`user_id`),
  CONSTRAINT `page_idFK` FOREIGN KEY (`page_id`)
  REFERENCES pages(`page_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT `user_idFK` FOREIGN KEY (`user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER sayfanin_takipciler BEFORE INSERT
ON sayfa_takipcileri
FOR EACH ROW
BEGIN
     if exists(select kurucu_user_id 
               from facebook_uygulamasi.pages
               where  kurucu_user_id = new.user_id 
               and pages.page_id=new.page_id) then
        signal sqlstate '45000' set message_text=" sayfanın kurucusunu normal takipçi olarak ekleyemezsiniz";
     end if;
   
END//
DELIMITER ;

DROP TRIGGER sayfanin_takipciler;

CREATE TABLE  `Facebook_Uygulamasi`.`social_groups` 
( 
  `group_id` INT(10) UNSIGNED NOT NULL,
  `kurucu_user_id` INT(10) UNSIGNED NOT NULL,
  `group_name` VARCHAR(256) NOT NULL,
  `hakkında` VARCHAR(256) NOT NULL,
   PRIMARY KEY (`group_id`),
   CONSTRAINT `unique_social_groups` UNIQUE (kurucu_user_id,group_name),
   CONSTRAINT `kurucu_user_id_grupFK` FOREIGN KEY (`kurucu_user_id`)
   REFERENCES users(`user_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);


CREATE TABLE  `Facebook_Uygulamasi`.`grup_uyeleri` 
( 
  `group_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
   CONSTRAINT `unique_followed_group` UNIQUE (`group_id`,`user_id`),
   CONSTRAINT `group_idFK` FOREIGN KEY (`group_id`)
   REFERENCES social_groups(`group_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE,
   CONSTRAINT `user_id_groupFK` FOREIGN KEY (`user_id`)
   REFERENCES users(`user_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER grubun_uyeleri BEFORE INSERT
ON grup_uyeleri
FOR EACH ROW
BEGIN
     if exists(select kurucu_user_id 
               from facebook_uygulamasi.social_groups 
               where  kurucu_user_id = new.user_id 
               and social_groups.group_id=new.group_id) then
        signal sqlstate '45000' set message_text=" grubun kurucusunu normal üye olarak ekleyemezsiniz";
     end if;
   
END//
DELIMITER ;

DROP TRIGGER grubun_uyeleri;

CREATE TABLE `Facebook_Uygulamasi`.`etkinlikler` (
  `etkinlik_id` INT UNSIGNED NOT NULL,
  `olusturan_user_id` INT UNSIGNED NOT NULL,
  `etkinlik_adi` VARCHAR(256) NOT NULL,
  `adress` VARCHAR(256) NOT NULL,
  `etkinlik_konumu` VARCHAR(256) NOT NULL,
  `Baslangic_tarihi` date  NOT NULL,
  `Bitis_tarihi` date  NOT NULL,
  `etkinlik_Aciklamasi` VARCHAR(256),
  `etkinlik_turu_Sayfa_Grup` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
   PRIMARY KEY (`etkinlik_id`),
   CONSTRAINT `unique_etkinlikler` UNIQUE (`etkinlik_adi`),
   CONSTRAINT `etkinlik_yeriFK` FOREIGN KEY (`etkinlik_konumu`)
   REFERENCES Sehir_Ulke(`sehir_ulke`)
   ON DELETE CASCADE
   ON UPDATE CASCADE,
   CONSTRAINT `etkinlikler_user_idFK` FOREIGN KEY (`olusturan_user_id`)
   REFERENCES users(`user_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);

CREATE TABLE  `Facebook_Uygulamasi`.`etkinlige_gidenler` 
( 
  `etkinlik_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
   CONSTRAINT `unique_etkinlige_gidenler` UNIQUE (`etkinlik_id`,`user_id`),
   CONSTRAINT `etkinlige_gidenlerFK` FOREIGN KEY (`etkinlik_id`)
   REFERENCES etkinlikler(`etkinlik_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE,
   CONSTRAINT `user_id_etkinlige_gidenlerFK` FOREIGN KEY (`user_id`)
   REFERENCES users(`user_id`)
   ON DELETE CASCADE
   ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER etkinlik BEFORE INSERT
ON etkinlikler
FOR EACH ROW
BEGIN
   IF (new.etkinlik_turu_Sayfa_Grup=1)  THEN 
     if not exists(select kurucu_user_id from facebook_uygulamasi.pages
                   where  (kurucu_user_id = new.olusturan_user_id)) then
        signal sqlstate '45000' set message_text=" etkinliği olusturan kayıtlı sayfa admini yok";
     end if;
   END IF;
   
   IF (new.etkinlik_turu_Sayfa_Grup=2)  THEN 
      if not exists(select kurucu_user_id from facebook_uygulamasi.social_groups 
                    where (kurucu_user_id  = new.olusturan_user_id)) then
        signal sqlstate '45000' set message_text=" etkinliği olusturan kayıtlı grup admini yok";
     end if;
   END IF;
   
END//
DELIMITER ;


DROP TRIGGER etkinlik;

CREATE TABLE  `Facebook_Uygulamasi`.`posts` 
( 
  `post_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
  `icerik` VARCHAR(256) NOT NULL,
  `date` date  NOT NULL,
  `ne_paylasimi` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`post_id`),
  CONSTRAINT `user_id_postFK` FOREIGN KEY (`user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER postlar BEFORE INSERT
ON posts
FOR EACH ROW
BEGIN
   IF (new.ne_paylasimi=1)  THEN 
      if not exists(select kurucu_user_id from facebook_uygulamasi.pages where  (kurucu_user_id = new.user_id)) then
        signal sqlstate '45000' set message_text=" paylaşımı yapabilecek kayıtlı sayfa admini yok";
     end if;
   END IF;
   
   IF (new.ne_paylasimi=2)  THEN 
       if not exists(select kurucu_user_id from facebook_uygulamasi.social_groups where (kurucu_user_id  = new.user_id)) then
        signal sqlstate '45000' set message_text="paylaşımı yapabilecek kayıtlı grup admini yok";
     end if;
   END IF;
   
END//
DELIMITER ;

DROP TRIGGER postlar;
 
CREATE TABLE  `Facebook_Uygulamasi`.`post_favs` 
( 
  `post_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
   CONSTRAINT `unique_followed_pages` UNIQUE (`post_id`,`user_id`),
  CONSTRAINT `post_idFK` FOREIGN KEY (`post_id`)
  REFERENCES posts(`post_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT `user_id_post_favFK` FOREIGN KEY (`user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE  `Facebook_Uygulamasi`.`posts_comments` 
( 
  `comment_id` INT(10) UNSIGNED NOT NULL,
  `post_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
  `icerik` VARCHAR(256) NOT NULL,
  `date` date  NOT NULL,
  PRIMARY KEY (`comment_id`),
  CONSTRAINT `post_id_commentsFK` FOREIGN KEY (`post_id`)
  REFERENCES posts(`post_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT `user_id_commentsFK` FOREIGN KEY (`user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);

CREATE TABLE  `Facebook_Uygulamasi`.`post_comment_favs` 
( 
  `comment_id` INT(10) UNSIGNED NOT NULL,
  `user_id` INT(10) UNSIGNED NOT NULL,
  CONSTRAINT `unique_followed_pages` UNIQUE (`comment_id`,`user_id`),
  CONSTRAINT `comment_idFK` FOREIGN KEY (`comment_id`)
  REFERENCES posts_comments(`comment_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
  CONSTRAINT `user_id_comment_favsFK` FOREIGN KEY (`user_id`)
  REFERENCES users(`user_id`)
  ON DELETE CASCADE
  ON UPDATE CASCADE
);


                                  /* SİLME VE GÜNCELLEME */
                                  
	
DELETE FROM users WHERE user_id=15 AND fname="tuna" and lname="karaman";

UPDATE friends SET arkadaslik_durumu=3  WHERE istek_gonderen_user_id=9 AND istegi_alan_user_id=10 ;

DELETE FROM posts_comments WHERE comment_id=7 AND post_id=11;

UPDATE pages SET page_name="soran insan" WHERE page_id=3;
	
DELETE FROM calistigi_yerler WHERE profil_id=15 AND sirket_adi="kafe pi";

UPDATE etkinlikler SET adress="ege palas" WHERE etkinlik_id=5;




                                   /* KAYITLAR */

    /*USERS KAYIT EKLEME */
    
INSERT INTO `users` (user_id,fname,lname,Born_date,sex,password,language,email)
VALUES(15,"tuna","karaman","1991-04-08","erkek",sha2('tuna', 256), "Spanish",'tuna@gmail.com' );

DELETE FROM users WHERE user_id=14;

SELECT * FROM users;


    /*DİLLER KAYIT EKLEME */
    
INSERT INTO `diller` (dil)
VALUES("Russian");

SELECT * FROM diller;


   /*SEHİR,ULKE KAYIT EKLEME */
   
INSERT INTO `Sehir_Ulke` (sehir_ulke)
VALUES("manchester,england");

SELECT * FROM Sehir_Ulke;


   /*PROFİL KAYIT EKLEME */

INSERT INTO `profil` (profil_id,user_id,biografi,yasadigi_yer,memleket)
VALUES(1,1,"izmiri severim","izmir,turkey","edirne,turkey");

SELECT * FROM profil;


  /* EGİTİM KAYIT EKLEME */
  
INSERT INTO `egitim` (profil_id,okul,basladıgı_tarih,bitirdigi_tarih,acıklama,bolum)
VALUES(7,"tobb universitesi","2009-09-24","2015-06-26","","ziraat muhendisligi");

SELECT * FROM egitim;


   /* CALISTIGI YERLER KAYIT EKLEME */

INSERT INTO `calistigi_yerler` (profil_id,sirket_adi,pozisyon,basladıgı_tarih,acıklama)
VALUES
(1,"lenda"," garson","2018-07-08","komi"),
(12,"folkart"," guvenlik gorevlisi","2018-07-08","");

SELECT * FROM calistigi_yerler;


    /* AYARLAR KAYIT EKLEME */
    
INSERT INTO `ayarlar` (user_id,arkadas_listesi_gizli_mi,paylasimlar_gizli_mi,takip_ettigin_sayfalari_kim_gorebilir,etiketlenen_gonderileri_kimler_gorebilir)
VALUES(15,0,0,2,2);

SELECT * FROM ayarlar;


   /*ARKADASLIK İLİŞKİLERİ KAYIT EKLEME */
   /*aynı iki kullanıcı eklenemez,girilen bir kayıt tekrar girilemez(orn: 2 1 / 1 2)*/

INSERT INTO `friends` (istek_gonderen_user_id,istegi_alan_user_id,arkadaslik_durumu) 
VALUES(2,1,1);

SELECT * FROM friends;


  /* MESAJLAR KAYIT EKLEME */
   /*( 12,8,7,14,1 nolu  kullanıcılar sayfaların yoneticisidir 
	   1,13,4,9,11,7 nolu kullanıcılar grupların yöneticisidir.)*/
   /* 7,3 / 7,8 arasındaki kayıtlar girilemez(aralarında engellenmis ilişkisi vardır)*/ 
  
  INSERT INTO `message` (alici_user_id,gonderici_user_id,spam_status,archived_status,unread_status,icerik,mesaj_turu) 
VALUES (11,13,0,1,0,"sana bir haberim var",1);

SELECT * FROM message;
   
DELETE FROM message WHERE alici_user_id=2;


   /*FACEBOOOK SAYFALARI KAYIT EKLEME  /*/

INSERT INTO `pages` (page_id,kurucu_user_id,page_name,hakkında) 
VALUES(1,12,"johanny bravo","cizgi film karakteri");

SELECT * FROM pages;



   /*FACEBOOOK SAYFA TAKİPÇİLERİ  KAYIT EKLEME */
   
   /*(1,12),(2,8),(3,7),(4,14),(5,1) nolu  kullanıcılar sayfaların yoneticisidir */

INSERT INTO `sayfa_takipcileri` (page_id,user_id) 
VALUES (1,12);

SELECT * FROM sayfa_takipcileri;


   /*FACEBOOOK GRUPLARI KAYIT EKLEME */

INSERT INTO `social_groups` (group_id,kurucu_user_id,group_name,hakkında) 
VALUES (6,7,"EVS","bir gönüllülük projesi");

SELECT * FROM social_groups;



   /*FACEBOOOK GRUP UYELERİ  KAYIT EKLEME */
   
  /* (1,1),(2,13),(3,4),(4,9),(5,11),(6,7) nolu kullanıcılar grupların yöneticisidir.)*/

INSERT INTO `grup_uyeleri` (group_id,user_id) 
VALUES (2,13);

SELECT * FROM grup_uyeleri;


   /*ETKİNLİKLER  KAYIT EKLEME */
      /*( 12,8,7,14,1 nolu  kullanıcılar sayfaların yoneticisidir 
	   1,13,4,9,11,7 nolu kullanıcılar grupların yöneticisidir.)*/
   
INSERT INTO `etkinlikler` (etkinlik_id,olusturan_user_id,etkinlik_adi,adress,
etkinlik_konumu,Baslangic_tarihi,Bitis_tarihi,etkinlik_Aciklamasi,etkinlik_turu_Sayfa_Grup) 
VALUES (7,13,"EVS nedir?","kordon","izmir,turkey","2009-12-12","2009-12-14","european volunteer service hakkında her şey",1);

SELECT * FROM etkinlikler;	



  /* ETKİNLİĞE GİDENLER KAYIT EKLEME*/
INSERT INTO `etkinlige_gidenler` (etkinlik_id,user_id) 
VALUES (5,8);

SELECT * FROM etkinlige_gidenler;


   /*POSTLAR  KAYIT EKLEME */
   /*( 12,8,7,14,1 nolu  kullanıcılar sayfaların yoneticisidir 
	   1,13,4,9,11,7 nolu kullanıcılar grupların yöneticisidir.)*/
   
INSERT INTO `posts` (post_id,user_id,icerik,date,ne_paylasimi) 
VALUES (16,14,"dogum gunumu kutlayan herkese tesekkurler","2018-12-12",2);


SELECT * FROM posts;


  /*POST BEĞENİLERİ  KAYIT EKLEME */
  
  
INSERT INTO `post_favs` (post_id,user_id) 
VALUES (9,9);

SELECT * FROM post_favs;



     /*POST YORUMLARI  KAYIT EKLEME */
     
INSERT INTO `posts_comments`(comment_id,post_id,user_id,icerik,date)
VALUES (7,11,1,"peaky blinders'ı unutma!!","2018-04-06");

SELECT * FROM posts_comments;

     
     /*POST YORUM BEĞENİLERİ  KAYIT EKLEME */

INSERT INTO `post_comment_favs` (comment_id,user_id) 
VALUES (1,9);

SELECT * FROM post_comment_favs;




	                                     /* SORGULAR */ 
                                         

/* adı aylin soyadı ersen olan kullanıcının takip ettiği sayfaların  bilgilerini listele*/
SELECT  pages.page_id,pages.page_name,pages.hakkında
FROM  pages,users
WHERE  page_id   IN
         (SELECT  sayfa_takipcileri.page_id
         FROM  sayfa_takipcileri
         WHERE users.user_id  = sayfa_takipcileri.user_id
         AND users.fname="aylin" AND  users.lname="ersen" );



/* adı fatih soyadı hurkivilcim olan kullanıcıya gelen ve okunmamıs olan mesajların içeriğini
ve gönderen kişinin adını ve soyadını görüntüle*/
SELECT message.icerik AS mesaj,B.fname AS gonderen_adı,B.lname AS gonderen_soyadı
FROM   users A,users B,message
WHERE  A.fname="fatih" AND  A.lname="hurkivilcim" AND A.user_id=message.alici_user_id AND 
       B.user_id=message.gonderici_user_id AND message.unread_status=1;



/* her sayfanın takipci sayısını görüntüleyiniz*/
SELECT pages.page_id,page_name, COUNT(sayfa_takipcileri.page_id) AS takipci_sayisi
FROM   pages,sayfa_takipcileri
WHERE  pages.page_id=sayfa_takipcileri.page_id
GROUP BY pages.page_id;



/* begeni sayısı 0 dan çok olan her grup postunu ve postu paylaşan grup bilgisini görüntüleyiniz */
SELECT posts.post_id,posts.icerik AS paylasım,COUNT(post_favs.post_id) AS begeni_sayisi,
social_groups.group_name AS paylasımı_yapan_grup_adi
FROM  posts,post_favs,social_groups
WHERE posts.post_id=post_favs.post_id and posts.ne_paylasimi=2 and posts.user_id=social_groups.kurucu_user_id
GROUP BY posts.post_id
HAVING  COUNT(post_favs.post_id)>0;



/* yasadığı yer izmir,turkiye olan her kullanıcının çalıştığı yerleri (sirket adi ve pozisyon) görüntüleyiniz */
SELECT users.user_id,users.fname,users.lname,calistigi_yerler.sirket_adi,calistigi_yerler.pozisyon
FROM   users,profil,calistigi_yerler
WHERE  profil.yasadigi_yer="izmir,turkey" AND users.user_id=profil.user_id AND profil.profil_id=calistigi_yerler.profil_id
GROUP BY users.user_id;



/* 12 user id'li kullanıcının oluşturduğu sayfa etkinliklerine giden tüm kullanıcıların isimlerini görüntüleyiniz*/
SELECT users.fname,users.lname
FROM users,etkinlikler,etkinlige_gidenler
WHERE etkinlikler.olusturan_user_id=12 AND etkinlikler.etkinlik_turu_Sayfa_Grup=1 
	   AND 	etkinlige_gidenler.user_id=users.user_id
       AND   etkinlikler.etkinlik_id=etkinlige_gidenler.etkinlik_id;



/* 1 No'lu post id'yi beğenen kullanıcıların isimleri ve çalıştıkları yerleri (şirket adi - pozisyonu) görüntüleyiniz.*/
SELECT users.fname,users.lname,calistigi_yerler.sirket_adi,calistigi_yerler.pozisyon
FROM post_favs,users,calistigi_yerler,profil 
WHERE post_favs.post_id=1 and post_favs.user_id = users.user_id and profil.user_id=users.user_id
and profil.profil_id = calistigi_yerler.profil_id;



/* memleketi bursa olan kullanıcıların isimleri, soyisimleri ve paylaştığı sayfa postlarını görüntüleyiniz*/
SELECT users.user_id,users.fname,users.lname,posts.icerik AS postun_içeriği
FROM profil,users,posts
WHERE profil.memleket="bursa,turkey" and profil.user_id=users.user_id and users.user_id = posts.user_id
and posts.ne_paylasimi = 1
GROUP BY users.user_id;



/* konumu izmir,turkey olarak olusturulan her grup etkinliklerinin bilgilerini(etkinlik adi) ,
   etkinlikleri olusturan sayfaların bilgilerini ve bu 
   etkinliklere gidenlerin sayısını görüntüleyiniz */
SELECT etkinlikler.etkinlik_id,etkinlikler.etkinlik_adi,social_groups.group_name AS etkinligi_olusturan_grup_adi,
       COUNT(etkinlige_gidenler.etkinlik_id) AS etkinlige_giden_sayisi
FROM   etkinlikler,social_groups,etkinlige_gidenler
WHERE  etkinlikler.etkinlik_konumu="izmir,turkey" and etkinlikler.etkinlik_turu_Sayfa_Grup=2 
       and etkinlikler.olusturan_user_id=social_groups.kurucu_user_id 
       and etkinlige_gidenler.etkinlik_id=etkinlikler.etkinlik_id
GROUP BY etkinlikler.etkinlik_id;



/*her  postun begeni sayısını görüntüleyiniz*/ 
SELECT posts.post_id,posts.icerik AS postun_içeriği, COUNT(post_favs.post_id) AS begeni_sayisi,
users.fname AS paylasım_yapan_isim,users.lname AS paylasım_yapan_soyisim
FROM   posts,post_favs,users
WHERE  post_favs.post_id=posts.post_id  and users.user_id=posts.user_id
GROUP BY posts.post_id;



/* adı safa soyadı orhan olan kullanıcının arkadas listesini göster */
SELECT  B.user_id,B.fname,B.lname
FROM    users A,users B,friends 
WHERE   A.fname="safa" AND  A.lname="orhan" 
        AND (A.user_id=friends.istek_gonderen_user_id OR  A.user_id=friends.istegi_alan_user_id) 
        AND (B.user_id=friends.istek_gonderen_user_id OR B.user_id=friends.istegi_alan_user_id)
        AND friends.arkadaslik_durumu=1 AND A.user_id != B.user_id;
   
   
/* en az 1 takipcisi olan sayfaları gösteriniz*/
select B.page_name
from pages as B
where exists ( select page_id
               from sayfa_takipcileri as S
               where s.page_id=B.page_id );
               
/* hiç begeni almayan paylasımları gösteriniz */
select P.icerik
from posts as P
where not exists(
				select F.post_id
                from post_favs as F 
                where F.post_id=p.post_id);


/* kullanıcı 5 tarafından paylasılmıs tum postları begenen kulanıcıları gösteriniz  */

select U.fname
from users AS U
where U.user_id in (
                         select U.user_id
                         from  post_favs,users as A,posts
                         where A.user_id=7 and posts.user_id=A.user_id and  post_favs.post_id=posts.post_id and 
                         post_favs.user_id=U.user_id );


/* ikiden fazla gidilen her etkinlik için etkinlik adi , etkinlik no , etkinliğe giden sayısını yazdırıınız */
select   E.etkinlik_id , E.etkinlik_adi,count(*)
from etkinlikler as E ,etkinlige_gidenler as G 
where E.etkinlik_id=G.etkinlik_id
group by  E.etkinlik_id
having count(*)>2;


/* 1 nolu sayfayı takip edip 2 nolu sayfayı takip etmeyen kullanıcıların isimlarini gösteriniz*/

select U.fname
from users as U,sayfa_takipcileri as S
where S.user_id=U.user_id and S.page_id=1
except
(select U.fname
from users as U,sayfa_takipcileri as S
where S.user_id=U.user_id and S.page_id=2);



SELECT * FROM users as b right JOIN etkinlikler as o ON b.user_id = o.olusturan_user_id;



DELIMITER //
CREATE TRIGGER ekle AFTER delete
ON users
FOR EACH ROW
BEGIN

DELETE FROM profil WHERE profil.user_id= old.user_id;
   
END//
DELIMITER ;

DROP TRIGGER ekle;





SELECT project.pno,pname,dname,count(works_on.pno),count(works_on.hours)
FROM   employee,department
WHERE  dnumber=dno 
GROUP BY dno
having avg(salary)>300000;





