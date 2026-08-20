# $Id: images.p,v 1.0.3.4 2005/11/11 Eugene Spearance Exp $

@CLASS
images

########################################
@auto[]
$script_path[/../bin]
$script_resize_name[nconvert]

# закоментировать следующие две строки если используется nconvert
$script_path[/../cgi-bin]
$script_resize_name[images.pl]

$script_convert_path[/../cgi-bin]
$script_convert_name[convert.pl]

$nconvert_path[/../bin]
### End @auto[]


################################################################################
# Сохраняет картинку в каталог $destination_path с именем $image_name.
# Проверяет является ли картинка jpeg, jpe, jpg, gif или png файлом.
# Если не задан путь $destination_path, картинка сохраняется в корневом каталоге (/).
# Если не указано имя файла $image_name, картинка сохраняется с текущим именем.
# Если указан $format[gif|jpg|jpeg|jpe|png], то картинка в него конвертируется 
################################################################################
@save[image_file;destination_path;image_name;remove_meta;format][script;file_image]
^if($image_file && $image_file is "file"){
	$destination_path[^_prepare_path[$destination_path]]
	^if(!def $image_name){$image_name[$image_file.name]}
	^if(^image_name.match[^^.+\.(jp(?=[eg])e?g?|gif|png)^$][i]){
		^if(def $format){
			^try{
				$script[$script_convert_path/$script_convert_name]
				^image_file.save[binary;$destination_path/temp_$image_name]
				$file_image[^file::exec[$script;
						$.CGI_FILE_IMAGE[${env:DOCUMENT_ROOT}$destination_path/temp_$image_name]
						$.CGI_FORMAT[$format]
					]
				]
				^file:delete[$destination_path/temp_$image_name]
			}{
				$exception.handled(1)
				$result(3)	# ошибка конвертирования
			}
		}{
			^image_file.save[binary;$destination_path/$image_name]
		}
		^if($remove_meta){
			$result(^remove_metadata[$destination_path/$image_name])
		}{
			$result(0)	# сохранение завершено
		}
	}{
		$result(1)	# формат файла не поддерживается
	}
}{
	$result(2)		# файл не определен
}
### End @save[]


################################################################################
# Изменяет размер картинки по ширине и высоте. Если задан только один размер, 
# второй подгоняется пропорционально.
# Сохраняет результат изменения в каталог $destination_path с именем $image_name.
# Если не указан путь $source_path, картинка берется из корневого каталога.
# Если не указан путь $destination_path, картинка сохраняется в $source_path.
################################################################################
@resize[params][script;source_path;destination_path;file_image]
^if(def $params && $params is "hash"){

	$result(0)	# изменение размера завершено
	
	^if(def $params.image_name){
		^try{
			$script[$script_path/$script_resize_name]
			
			$source_path[^_prepare_path[$params.source_path]]
			
			^if(!-f "$source_path/$params.image_name"){
				^throw[image_file.missing;resize;source image is missing]
			}

			^if(def $params.destination_path){
				$destination_path[^_prepare_path[$params.destination_path]]
			}{
				$destination_path[$source_path]
			}
			^switch[$script_resize_name]{
				^case[nconvert]{
					$file_image[^file::exec[$script;;-o;${env:DOCUMENT_ROOT}$destination_path/$params.image_name;-q;^if(^params.quality.int(0) > 0){$params.quality}{80};^if(^params.x_size.int(0) > 0 && ^params.y_size.int(0) > 0){-normalize}{-ratio};-resize;^if(^params.x_size.int(0) > 0){$params.x_size};^if(^params.y_size.int(0) > 0){$params.y_size};${env:DOCUMENT_ROOT}$source_path/$params.image_name]]
				}
				^case[DEFAULT]{
					$file_image[^file::exec[$script;
						$.CGI_SOURCE_PATH[${env:DOCUMENT_ROOT}$source_path]
						$.CGI_DESTINATION_PATH[${env:DOCUMENT_ROOT}$destination_path]
						$.CGI_IMAGE_NAME[$params.image_name]
						^if(^params.x_size.int(0) > 0){$.CGI_X_SIZE[$params.x_size]}
						^if(^params.y_size.int(0) > 0){$.CGI_Y_SIZE[$params.y_size]}
						^if(^params.quality.int(0) > 0){$.CGI_QUALITY[$params.quality]}
					]]
				}
			}
			^if($file_image.status){
				^throw[script.error;resize;$script_resize_name script error: $file_image.stderr]
			}
		}{
			^switch[$exception.type]{
				^case[image_file.missing]{$result(3)}	# исходный файл не найден			
				^case[script_file.missing]{$result(4)}	# скрипт (images.pl|nconvert) отсутствует
				^case[script.error]{$result(5)}		# не получилось выполнить (images.pl|nconvert) скрипт
			}
			$exception.handled(1)
		}
	}{
		$result(2)	# не задано имя файла
	}
}{
	$result(1)	# параметры не заданы
}
### End @resize[]


################################################################################
@remove_metadata[path]
$result(0)
^try{
	$file_image[^file::exec[$nconvert_path/nconvert;;-o;${env:DOCUMENT_ROOT}$path;-q;80;-rmeta;-rexifthumb;${env:DOCUMENT_ROOT}$path]]
}{
	$result(4)	# ошибка удаления данных
	$exception.handled(1)
}
### End @remove_metadata[]


################################################################################
# вспомогательный метод, удаляет слеши в конце строки если они есть
################################################################################
@_prepare_path[path]
^if(def $path){
	$result[^path.trim[end;/]]
}
### End @_prepare_path[]