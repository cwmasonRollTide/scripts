function Compare-Strings {
<#
   .SYNOPSIS
      Compares two strings character by character and checks if the number of differences is less than or equal to a given Tolerance.
      Length doesn't matter, only the number of differences between the two strings. But if one string is longer than the other, the differences will be incremented for each additional character.

   .DESCRIPTION
      The Compare-Strings function takes in two strings and a Tolerance value. It iterates over each character in the first string and compares it with the corresponding character in the second string. If the characters are not equal, it increments a differences counter. Finally, it checks if the total number of differences is less than or equal to the Tolerance value.

   .PARAMETER Str1
      The first string to compare.

   .PARAMETER Str2
      The second string to compare.

   .PARAMETER Tolerance
      The maximum number of character differences allowed between the two strings.

   .EXAMPLE
      Compare-Strings -Str1 "hello" -Str2 "helli" -Tolerance 1
      Returns True because there is only one character difference between the two strings, which is less than or equal to the Tolerance.

   .OUTPUTS
      Boolean. Returns True if the number of character differences between the two strings is less than or equal to the Tolerance, otherwise False.

   .NOTES
      This function is used to compare two strings and check if the number of differences is less than or equal to a given Tolerance.
      Author: Connor Mason
      Date: 10/2/2024
#>
[CmdletBinding()]
Param(
   [string]$Str1,
   [string]$Str2,
   [int]$Tolerance
)
   $differences = 0
   $maxLength = [Math]::Max($Str1.Length, $Str2.Length)
   $minLength = [Math]::Min($Str1.Length, $Str2.Length)

   for ($i = 0; $i -lt $maxLength; $i++) {
      if ($i -lt $minLength) {
         if ($Str1[$i] -ne $Str2[$i]) {
            $differences++
         }
      } else {
         $differences++
      }

      if ($differences > $Tolerance) {
         return $false
      }
   }

   return $differences -le $Tolerance
}