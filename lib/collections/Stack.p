@CLASS
Stack


@create[]
$h[^hash::create[]]
$i(0)



@push[uValue]
$i($i+1)
$h.$i[$uValue]
$result[]



@pop[]
^if(!$i){
	^throw[$self.CLASS_NAME;Stack is empty.]
}
$result[$h.$i]
^h.delete[$i]
$i($i-1)



@count[]
$result[^h._count[]]
