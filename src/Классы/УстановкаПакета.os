﻿#Использовать fs
#Использовать logos
#Использовать tempfiles

Перем Лог;
Перем мВременныйКаталогУстановки;
Перем мЗависимостиВРаботе;
Перем ЭтоWindows;
Перем мРежимУстановкиПакетов;
Перем КэшУстановленныхПакетов;

Процедура УстановитьПакетИзАрхива(Знач ФайлАрхива) Экспорт
	
	Лог.Отладка("Устанавливаю пакет из архива: " + ФайлАрхива);
	Если мЗависимостиВРаботе = Неопределено Тогда
		мЗависимостиВРаботе = Новый Соответствие;
	КонецЕсли;
	
	мВременныйКаталогУстановки = ВременныеФайлы.СоздатьКаталог();
	Лог.Отладка("Временный каталог установки: " + мВременныйКаталогУстановки);
	
	Попытка
		
		Лог.Отладка("Открываем архив пакета");
		ЧтениеПакета = Новый ЧтениеZipФайла;
		ЧтениеПакета.Открыть(ФайлАрхива);
		
		ФайлСодержимого = ИзвлечьОбязательныйФайл(ЧтениеПакета, КонстантыOpm.ИмяФайлаСодержимогоПакета);
		ФайлМетаданных  = ИзвлечьОбязательныйФайл(ЧтениеПакета, КонстантыOpm.ИмяФайлаМетаданныхПакета);
		
		Метаданные = ПрочитатьМетаданныеПакета(ФайлМетаданных);
		ИмяПакета = Метаданные.Свойства().Имя;
		
		ПутьУстановки = НайтиСоздатьКаталогУстановки(ИмяПакета);
		Лог.Информация("Устанавливаю пакет " +  ИмяПакета);
		ПроверитьВерсиюСреды(Метаданные);
		Если мЗависимостиВРаботе[ИмяПакета] = "ВРаботе" Тогда
			ВызватьИсключение "Циклическая зависимость по пакету " + ИмяПакета;
		КонецЕсли;
		
		мЗависимостиВРаботе.Вставить(ИмяПакета, "ВРаботе");
		
		РазрешитьЗависимостиПакета(Метаданные);
		
		СтандартнаяОбработка = Истина;
		УстановитьФайлыПакета(ПутьУстановки, ФайлСодержимого, СтандартнаяОбработка);
		Если СтандартнаяОбработка Тогда
			СгенерироватьСкриптыЗапускаПриложенийПриНеобходимости(ПутьУстановки.ПолноеИмя, Метаданные);
		КонецЕсли;
		СохранитьФайлМетаданныхПакета(ПутьУстановки.ПолноеИмя, ФайлМетаданных);
		
		ЧтениеПакета.Закрыть();
		
		ВременныеФайлы.УдалитьФайл(мВременныйКаталогУстановки);
		
		мЗависимостиВРаботе.Вставить(ИмяПакета, "Установлен");
		
	Исключение
		ЧтениеПакета.Закрыть();
		ВременныеФайлы.УдалитьФайл(мВременныйКаталогУстановки);
		ВызватьИсключение;
	КонецПопытки;
	
	Лог.Информация("Установка завершена");
	
КонецПроцедуры

Процедура ПроверитьВерсиюСреды(Манифест)
	
	Свойства = Манифест.Свойства();
	Если НЕ Свойства.Свойство("ВерсияСреды") Тогда
		Возврат;
	КонецЕсли;
	
	ИмяПакета = Свойства.Имя;
	ТребуемаяВерсияСреды = Свойства.ВерсияСреды;
	СистемнаяИнформация = Новый СистемнаяИнформация;
	ВерсияСреды = СистемнаяИнформация.Версия;
	Лог.Отладка("ПроверитьВерсиюСреды: Перед вызовом СравнитьВерсии(ЭтаВерсия = <%1>, БольшеЧемВерсия = <%2>)", ТребуемаяВерсияСреды, ВерсияСреды);
	Если РаботаСВерсиями.СравнитьВерсии(ТребуемаяВерсияСреды, ВерсияСреды) > 0 Тогда
		ТекстСообщения = СтрШаблон(
		"Ошибка установки пакета <%1>: Обнаружена устаревшая версия движка OneScript.
		|Требуемая версия: %2
		|Текущая версия: %3
		|Обновите OneScript перед установкой пакета", 
		ИмяПакета,
		ТребуемаяВерсияСреды,
		ВерсияСреды
	);
	
	ВызватьИсключение ТекстСообщения;
КонецЕсли;

КонецПроцедуры

Процедура УстановитьПакетыПоОписаниюПакета() Экспорт
	
	ОписаниеПакета = РаботаСОписаниемПакета.ПрочитатьОписаниеПакета();
	
	ПроверитьВерсиюСреды(ОписаниеПакета);
	
	РазрешитьЗависимостиПакета(ОписаниеПакета);
	
КонецПроцедуры

Процедура УдалитьКаталогУстановкиПриОшибке(Знач Каталог)
	Лог.Отладка("Удаляю каталог " + Каталог);
	Попытка
		УдалитьФайлы(Каталог);
	Исключение
		Лог.Отладка("Не удалось удалить каталог " + Каталог + "
		|	- " + ОписаниеОшибки());
	КонецПопытки
КонецПроцедуры

Процедура УстановитьПакетИзОблака(Знач ИмяПакета) Экспорт
	
	ИмяВерсияПакета = РаботаСВерсиями.РазобратьИмяПакета(ИмяПакета);
	СкачатьИУстановитьПакет(ИмяВерсияПакета.ИмяПакета, ИмяВерсияПакета.Версия);
	
КонецПроцедуры

Процедура УстановитьВсеПакетыИзОблака() Экспорт
	
	КэшПакетовХаба = Новый КэшПакетовХаба();
	ПакетыХаба = КэшПакетовХаба.ПолучитьПакетыХаба();
	Для Каждого КлючИЗначение Из ПакетыХаба Цикл
		УстановитьПакетИзОблака(КлючИЗначение.Ключ);
	КонецЦикла;
	
КонецПроцедуры

Процедура ОбновитьПакетИзОблака(Знач ИмяПакета) Экспорт
	
	ИмяВерсияПакета = РаботаСВерсиями.РазобратьИмяПакета(ИмяПакета);
	СкачатьИУстановитьПакет(ИмяВерсияПакета.ИмяПакета, ИмяВерсияПакета.Версия);
	
КонецПроцедуры

Процедура ОбновитьУстановленныеПакеты() Экспорт
	КэшУстановленныхПакетов = ПолучитьУстановленныеПакеты();
	УстановленныеПакеты = КэшУстановленныхПакетов.ПолучитьУстановленныеПакеты();
	Для Каждого КлючИЗначение Из УстановленныеПакеты Цикл
		ОбновитьПакетИзОблака(КлючИЗначение.Ключ);
	КонецЦикла;
КонецПроцедуры

Процедура УстановитьРежимУстановкиПакетов(Знач ЗначениеРежимУстановкиПакетов) Экспорт
	мРежимУстановкиПакетов = ЗначениеРежимУстановкиПакетов;
КонецПроцедуры

Функция НайтиСоздатьКаталогУстановки(Знач ИдентификаторПакета)
	
	Если мРежимУстановкиПакетов = РежимУстановкиПакетов.Локально Тогда
		КаталогБиблиотек = КонстантыOpm.ЛокальныйКаталогУстановкиПакетов;
	ИначеЕсли мРежимУстановкиПакетов = РежимУстановкиПакетов.Глобально Тогда
		КаталогБиблиотек = КаталогСистемныхБиблиотек();
	Иначе
		ВызватьИсключение "Неизвестный режим установки пакетов <" + мРежимУстановкиПакетов + ">";
	КонецЕсли;
	ПутьУстановки = Новый Файл(ОбъединитьПути(КаталогБиблиотек, ИдентификаторПакета));
	Лог.Отладка("Путь установки пакета: " + ПутьУстановки.ПолноеИмя);
	
	Если Не ПутьУстановки.Существует() Тогда
		СоздатьКаталог(ПутьУстановки.ПолноеИмя);
	ИначеЕсли ПутьУстановки.ЭтоФайл() Тогда
		ВызватьИсключение "Не удалось создать каталог " + ПутьУстановки.ПолноеИмя;
	КонецЕсли;
	
	Возврат ПутьУстановки;
	
КонецФункции

Процедура РазрешитьЗависимостиПакета(Знач Манифест)
	
	Зависимости = Манифест.Зависимости();
	Если Зависимости.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	УстановленныеПакеты = ПолучитьУстановленныеПакеты();
	
	Для Каждого Зависимость Из Зависимости Цикл
		Лог.Информация("Устанавливаю зависимость: " + Зависимость.ИмяПакета);

		Если Не УстановленныеПакеты.ПакетУстановлен(Зависимость) Тогда
			// скачать
			// определить зависимости и так по кругу
			СкачатьИУстановитьПакетПоОписанию(Зависимость);
			УстановленныеПакеты.Обновить();
		Иначе
			Лог.Информация("" + Зависимость.ИмяПакета + " уже установлен. Пропускаем.");
			// считаем, что версия всегда подходит
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

Функция ПолучитьУстановленныеПакеты()

	Если КэшУстановленныхПакетов = Неопределено Тогда

		КэшУстановленныхПакетов = Новый КэшУстановленныхПакетов();

		Если мРежимУстановкиПакетов = РежимУстановкиПакетов.Локально Тогда

			ПутьККаталогуЛокальнойУстановки = ОбъединитьПути(
					ТекущийКаталог(),
					КонстантыOpm.ЛокальныйКаталогУстановкиПакетов
			);

			КэшУстановленныхПакетов.ДобавитьКаталогБиблиотек(ПутьККаталогуЛокальнойУстановки);

		КонецЕсли;

	КонецЕсли;

	Возврат КэшУстановленныхПакетов;

КонецФункции

Процедура СкачатьИУстановитьПакетПоОписанию(Знач ОписаниеПакета)
	// TODO: Нужно скачивание конкретной версии по маркеру
	СкачатьИУстановитьПакет(ОписаниеПакета.ИмяПакета, ОписаниеПакета.МинимальнаяВерсия);
КонецПроцедуры

// Функция по имени пакета определяет имя архива в хабе
// https://github.com/oscript-library/opm/issues/50
// Имена файлов в хабе регистрозависимы, однако имена пакетов по обыкновению регистронезависимы
Функция ОпределитьИмяАрхива(Знач ИмяПакета)

	КэшПакетовВХабе = Новый КэшПакетовХаба();
	ПакетыХаба = КэшПакетовВХабе.ПолучитьПакетыХаба();

	Если ПакетыХаба.Получить(ИмяПакета) = Неопределено Тогда

		Для Каждого мПакет Из ПакетыХаба Цикл

			// Проводим регистронезависимое сравнение имён
			Если нрег(мПакет.Ключ) = нрег(ИмяПакета) Тогда

				// и возвращаем ровно то имя, которое хранится в хабе (с учётом регистра)
				Возврат мПакет.Ключ;

			КонецЕсли;

		КонецЦикла;

		Возврат Неопределено;

	КонецЕсли;

	Возврат ИмяПакета;

КонецФункции

Процедура СкачатьИУстановитьПакет(Знач ИмяПакета, Знач ВерсияПакета)
	
	ИмяАрхива = ОпределитьИмяАрхива(ИмяПакета);
	Если ИмяАрхива = Неопределено Тогда
		ТекстИсключения = СтрШаблон("Ошибка установки пакета %1: Пакет не найден", ИмяПакета);
		ВызватьИсключение ТекстИсключения;
	КонецЕсли;

	Если ВерсияПакета <> Неопределено Тогда
		ФайлПакета = ИмяАрхива + "-" + ВерсияПакета + ".ospx";
	Иначе
		ФайлПакета = ИмяАрхива + ".ospx";
	КонецЕсли;
	
	Лог.Информация("Скачиваю файл: " + ФайлПакета);
	
	Ответ  = Зеркала.ПолучитьРесурс(ИмяАрхива + "/" + ФайлПакета);
	Если Не Ответ = Неопределено Тогда
		Лог.Отладка("Файл получен");
		ВремФайл = ОбъединитьПути(КаталогВременныхФайлов(), ФайлПакета);
		Ответ.ПолучитьТелоКакДвоичныеДанные().Записать(ВремФайл);
		Ответ.Закрыть();
		Лог.Отладка("Соединение закрыто");
		Попытка
			УстановитьПакетИзАрхива(ВремФайл);
			УдалитьФайлы(ВремФайл);
		Исключение
			УдалитьФайлы(ВремФайл);
			ВызватьИсключение;
		КонецПопытки;
	Иначе
		ТекстИсключения = СтрШаблон("Ошибка установки пакета %1: Нет соединения", ИмяПакета);
		ВызватьИсключение ТекстИсключения;
	КонецЕсли;
	
КонецПроцедуры

Функция ИнициализироватьСоединение(Сервер) Экспорт
	
	НастройкиПрокси = НастройкиПриложенияOpm.Получить().Прокси;
	Если НастройкиПрокси.ИспользоватьПрокси Тогда
		Прокси = Новый ИнтернетПрокси(НастройкиПрокси.ПроксиПоУмолчанию);
		Если Не НастройкиПрокси.ПроксиПоУмолчанию Тогда
			Прокси.Установить("http",НастройкиПрокси.Сервер,НастройкиПрокси.Порт,НастройкиПрокси.Пользователь,НастройкиПрокси.Пароль,НастройкиПрокси.ИспользоватьАутентификациюОС);
		КонецЕсли;	
		Соединение = Новый HTTPСоединение(Сервер,,,,Прокси);
	Иначе
		Соединение = Новый HTTPСоединение(Сервер);
	КонецЕсли;
	
	Возврат Соединение;
	
КонецФункции	

Функция РазобратьМаркерВерсии(Знач МаркерВерсии)
	
	Перем ИндексВерсии;
	
	Оператор = Лев(МаркерВерсии, 1);
	Если Оператор = "<" или Оператор = ">" Тогда
		ТестОператор = Сред(МаркерВерсии, 2, 1);
		Если ТестОператор = "=" Тогда
			ИндексВерсии = 3;
		Иначе
			ИндексВерсии = 2;
		КонецЕсли;
	ИначеЕсли Оператор = "=" Тогда
		ИндексВерсии = 2;
	ИначеЕсли Найти("0123456789", Оператор) > 0 Тогда
		ИндексВерсии = 1;
	Иначе
		ВызватьИсключение "Некорректно задан маркер версии";
	КонецЕсли;
	
	Если ИндексВерсии > 1 Тогда
		Оператор = Лев(МаркерВерсии, ИндексВерсии-1);
	Иначе
		Оператор = "";
	КонецЕсли;
	
	Версия = Сред(МаркерВерсии, ИндексВерсии);
	
	Возврат Новый Структура("Оператор,Версия", Оператор, Версия);
	
КонецФункции

Функция КаталогСистемныхБиблиотек()
	
	СистемныеБиблиотеки = ОбъединитьПути(КаталогПрограммы(), ПолучитьЗначениеСистемнойНастройки("lib.system"));
	Лог.Отладка("СистемныеБиблиотеки " + СистемныеБиблиотеки);
	Если СистемныеБиблиотеки = Неопределено Тогда
		ВызватьИсключение "Не определен каталог системных библиотек";
	КонецЕсли;
	
	Возврат СистемныеБиблиотеки;
	
КонецФункции

Процедура УстановитьФайлыПакета(Знач ПутьУстановки, Знач ФайлСодержимого, СтандартнаяОбработка)
	
	ЧтениеСодержимого = Новый ЧтениеZipФайла(ФайлСодержимого);
	Попытка	
		ИмяСкриптаУстановки = КонстантыOpm.ИмяФайлаСкриптаУстановки;
		ЭлементСкриптаУстановки = ЧтениеСодержимого.Элементы.Найти(ИмяСкриптаУстановки);
		Если ЭлементСкриптаУстановки <> Неопределено Тогда
			Лог.Отладка("Найден скрипт установки пакета");
			
			ЧтениеСодержимого.Извлечь(ЭлементСкриптаУстановки, мВременныйКаталогУстановки, РежимВосстановленияПутейФайловZIP.НеВосстанавливать);
			Лог.Отладка("Компиляция скрипта установки пакета");
			ОбъектСкрипта = ЗагрузитьСценарий(ОбъединитьПути(мВременныйКаталогУстановки, ИмяСкриптаУстановки));
			
			ВызватьСобытиеПередУстановкой(ОбъектСкрипта, ЧтениеСодержимого, ПутьУстановки.ПолноеИмя, СтандартнаяОбработка);
			
			Если СтандартнаяОбработка Тогда
				
				Лог.Отладка("Устанавливаю файлы пакета из архива");
				УдалитьУстаревшиеФайлы(ПутьУстановки);
				ЧтениеСодержимого.ИзвлечьВсе(ПутьУстановки.ПолноеИмя);
				
				ВызватьСобытиеПриУстановке(ОбъектСкрипта, ПутьУстановки.ПолноеИмя, СтандартнаяОбработка);
				
			КонецЕсли;
		Иначе
			Лог.Отладка("Устанавливаю файлы пакета из архива");
			УдалитьУстаревшиеФайлы(ПутьУстановки);
			ЧтениеСодержимого.ИзвлечьВсе(ПутьУстановки.ПолноеИмя);
		КонецЕсли;
	Исключение
		ЧтениеСодержимого.Закрыть();
		ВызватьИсключение;
	КонецПопытки;
	
	ЧтениеСодержимого.Закрыть();
	
КонецПроцедуры

Процедура УдалитьУстаревшиеФайлы(Знач ПутьУстановки)
	УдалитьФайлыВКаталоге(ПутьУстановки.ПолноеИмя, "*.os", Истина);
	УдалитьФайлыВКаталоге(ПутьУстановки.ПолноеИмя, "*.dll", Истина);
КонецПроцедуры

Процедура УдалитьФайлыВКаталоге(Знач ПутьКаталога, Знач МаскаФайлов, Знач ИскатьВПодкаталогах = Истина)
	ФайлыДляУдаления = НайтиФайлы(ПутьКаталога, МаскаФайлов, ИскатьВПодкаталогах);
	Для Каждого Файл из ФайлыДляУдаления Цикл
		УдалитьФайлы(Файл.ПолноеИмя);
	КонецЦикла;
КонецПроцедуры

Процедура ВызватьСобытиеПередУстановкой(Знач ОбъектСкрипта, Знач АрхивПакета, Знач Каталог, СтандартнаяОбработка)
	Лог.Отладка("Вызываю событие ПередУстановкой");
	ОбъектСкрипта.ПередУстановкой(АрхивПакета, Каталог, СтандартнаяОбработка);
КонецПроцедуры

Процедура ВызватьСобытиеПриУстановке(Знач ОбъектСкрипта, Знач Каталог, СтандартнаяОбработка)
	Лог.Отладка("Вызываю событие ПриУстановке");
	ОбъектСкрипта.ПриУстановке(Каталог, СтандартнаяОбработка);
КонецПроцедуры

Процедура СгенерироватьСкриптыЗапускаПриложенийПриНеобходимости(Знач КаталогУстановки, Знач ОписаниеПакета)
	
	ИмяПакета = ОписаниеПакета.Свойства().Имя;
	
	Для Каждого ФайлПриложения Из ОписаниеПакета.ИсполняемыеФайлы() Цикл
		
		ИмяСкриптаЗапуска = ?(ПустаяСтрока(ФайлПриложения.ИмяПриложения), ИмяПакета, ФайлПриложения.ИмяПриложения);
		Лог.Информация("Регистрация приложения: " + ИмяСкриптаЗапуска);
		
		ОбъектФайл = Новый Файл(ОбъединитьПути(КаталогУстановки, ФайлПриложения.Путь));
		
		Если Не ОбъектФайл.Существует() Тогда
			Лог.Ошибка("Файл приложения " + ОбъектФайл.ПолноеИмя + " не существует");
			ВызватьИсключение "Некорректные данные в метаданных пакета";
		КонецЕсли;
		
		Если мРежимУстановкиПакетов = РежимУстановкиПакетов.Локально Тогда
			КаталогУстановкиСкриптовЗапускаПриложений = ОбъединитьПути(КонстантыOpm.ЛокальныйКаталогУстановкиПакетов, "bin");
			ФС.ОбеспечитьКаталог(КаталогУстановкиСкриптовЗапускаПриложений);
			КаталогУстановкиСкриптовЗапускаПриложений = Новый Файл(КаталогУстановкиСкриптовЗапускаПриложений).ПолноеИмя;
		ИначеЕсли мРежимУстановкиПакетов = РежимУстановкиПакетов.Глобально Тогда
			КаталогУстановкиСкриптовЗапускаПриложений = ?(ЭтоWindows, КаталогПрограммы(), "/usr/bin");
		Иначе
			ВызватьИсключение "Неизвестный режим установки пакетов <" + мРежимУстановкиПакетов + ">";
		КонецЕсли;
		
		СоздатьСкриптЗапуска(ИмяСкриптаЗапуска, ОбъектФайл.ПолноеИмя, КаталогУстановкиСкриптовЗапускаПриложений);
	
	КонецЦикла;
	
КонецПроцедуры

Процедура СоздатьСкриптЗапуска(Знач ИмяСкриптаЗапуска, Знач ПутьФайлаПриложения, Знач Каталог) Экспорт

	Если ЭтоWindows Тогда
		ФайлЗапуска = Новый ЗаписьТекста(ОбъединитьПути(Каталог, ИмяСкриптаЗапуска + ".bat"), "cp866");
		ФайлЗапуска.ЗаписатьСтроку("@oscript.exe """ + ПутьФайлаПриложения + """ %*");
		ФайлЗапуска.ЗаписатьСтроку("@exit /b %ERRORLEVEL%");
		ФайлЗапуска.Закрыть();
	КонецЕсли;

	Если (ЭтоWindows И НастройкиПриложенияOpm.Получить().СоздаватьShСкриптЗапуска) ИЛИ НЕ ЭтоWindows Тогда
		ПолныйПутьКСкриптуЗапуска = ОбъединитьПути(Каталог, ИмяСкриптаЗапуска);
		ФайлЗапуска = Новый ЗаписьТекста(ПолныйПутьКСкриптуЗапуска, КодировкаТекста.UTF8NoBOM,,, Символы.ПС);
		ФайлЗапуска.ЗаписатьСтроку("#!/bin/bash");
		СтрокаЗапуска = "oscript";
		Если ЭтоWindows Тогда
			СтрокаЗапуска = СтрокаЗапуска + " -encoding=utf-8";
		КонецЕсли;
		СтрокаЗапуска = СтрокаЗапуска + " """ + ПутьФайлаПриложения + """ ""$@""";
		ФайлЗапуска.ЗаписатьСтроку(СтрокаЗапуска);
		ФайлЗапуска.Закрыть();

		Если НЕ ЭтоWindows Тогда
			ЗапуститьПриложение("chmod +x """ + ПолныйПутьКСкриптуЗапуска + """");
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

Функция ПрочитатьМетаданныеПакета(Знач ФайлМетаданных)
	
	Перем Метаданные;
	Лог.Отладка("Чтение метаданных пакета");
	Попытка
		Чтение = Новый ЧтениеXML;
		Чтение.ОткрытьФайл(ФайлМетаданных);
		Лог.Отладка("XML загружен");
		Сериализатор = Новый СериализацияМетаданныхПакета;
		Метаданные = Сериализатор.ПрочитатьXML(Чтение);
		
		Чтение.Закрыть();
	Исключение
		Чтение.Закрыть();
		ВызватьИсключение;
	КонецПопытки;
	Лог.Отладка("Метаданные прочитаны");
	
	Возврат Метаданные;
	
КонецФункции

Процедура СохранитьФайлМетаданныхПакета(Знач КаталогУстановки, Знач ПутьКФайлуМетаданных)
	
	ПутьСохранения = ОбъединитьПути(КаталогУстановки, КонстантыOpm.ИмяФайлаМетаданныхПакета);
	ДанныеФайла = Новый ДвоичныеДанные(ПутьКФайлуМетаданных);
	ДанныеФайла.Записать(ПутьСохранения);
	
КонецПроцедуры

//////////////////////////////////////////////////////////////////////////////////
//

Функция ИзвлечьОбязательныйФайл(Знач Чтение, Знач ИмяФайла)
	Лог.Отладка("Извлечение: " + ИмяФайла);
	Элемент = Чтение.Элементы.Найти(ИмяФайла);
	Если Элемент = Неопределено Тогда
		ВызватьИсключение "Неверная структура пакета. Не найден файл " + ИмяФайла;
	КонецЕсли;
	
	Чтение.Извлечь(Элемент, мВременныйКаталогУстановки);
	
	Возврат ОбъединитьПути(мВременныйКаталогУстановки, ИмяФайла);
	
КонецФункции

Лог = Логирование.ПолучитьЛог("oscript.app.opm");
СИ = Новый СистемнаяИнформация();
ЭтоWindows = Найти(СИ.ВерсияОС, "Windows") > 0;
мРежимУстановкиПакетов = РежимУстановкиПакетов.Глобально;
