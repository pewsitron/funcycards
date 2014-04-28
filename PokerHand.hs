module PokerHand (
  Hand(..),
  HandCateg(..),
  compareHands,
  evaluateHand,
  highCardValue
) where

import Data.List
import Card

type Hand = [Card]

data HandCateg = HighCard
               | Pair
               | TwoPair
               | ThreeOfAKind
               | Straight
               | Flush
               | FullHouse
               | FourOfAKind
               | StraightFlush
               | RoyalFlush
               deriving (Eq, Ord, Bounded, Enum, Show, Read)

compareHands :: Hand -> Hand -> Ordering
compareHands [] [] = EQ
compareHands xs [] = GT
compareHands [] ys = LT
compareHands xs ys
    | evaluateHand xs /= evaluateHand ys = (evaluateHand xs) `compare` (evaluateHand ys)
    | otherwise = case evaluateHand xs
                  of   HighCard      -> compareHighCards xs ys
                       Pair          -> compareNOfKind 2 xs ys
                       TwoPair       -> compareNOfKind 2 xs ys
                       ThreeOfAKind  -> compareNOfKind 3 xs ys
                       Straight      -> compareHighCards xs ys
                       Flush         -> compareHighCards xs ys
                       FullHouse     -> compareFullHouse xs ys
                       FourOfAKind   -> compareNOfKind 4 xs ys
                       StraightFlush -> compareHighCards xs ys
                       RoyalFlush    -> EQ

compareHighCards :: Hand -> Hand -> Ordering
compareHighCards [] [] = EQ
compareHighCards xs [] = GT
compareHighCards [] ys = LT
compareHighCards xs ys
    | last valx /= last valy = (last valx) `compare` (last valy)
    | otherwise = compareHighCards (init xs) (init ys)
    where
        valx = sort (values xs)
        valy = sort (values ys)

{-
 - Compares the n-of-a-kind hands of two players. The one who has
 - n cards of the same higher face value is judged greater. If
 - both players have n cards of the same value, then the remaining
 - high cards determine the ordering. This works also for
 - comparing hands of two pairs with n=2 because a list is made
 - of the values of the pairs and then compared using
 - compareSortedValues.
 -
 - See: compareSortedValues
-}
compareNOfKind :: Int -> Hand -> Hand -> Ordering
compareNOfKind _ [] [] = EQ
compareNOfKind _ xs [] = GT
compareNOfKind _ [] ys = LT
compareNOfKind n xs ys
    | valOfKind valx /= valOfKind valy = (valOfKind valx) `compareSortedValues` (valOfKind valy)
    | otherwise = (valHigh valx) `compareSortedValues` (valHigh valy)
    where
        valx = sort (values xs)
        valy = sort (values ys)
        valOfKind xs = [head x | x <- (group xs), length x == n]
        valHigh xs = [head x | x <- (group xs), length x == 1]

compareFullHouse :: Hand -> Hand -> Ordering
compareFullHouse [] [] = EQ
compareFullHouse xs [] = GT
compareFullHouse [] ys = LT
compareFullHouse xs ys
    | compareNOfKind 3 xs ys /= EQ = compareNOfKind 2 xs ys
    | otherwise = compareNOfKind 3 xs ys

compareSortedValues :: [Value] -> [Value] -> Ordering
compareSortedValues [] [] = EQ
compareSortedValues xs [] = GT
compareSortedValues [] ys = LT
compareSortedValues xs ys
    | head xs == head ys = compareSortedValues (tail xs) (tail ys)
    | otherwise = (head xs) `compare` (head ys)

evaluateHand :: Hand -> HandCateg
evaluateHand [] = error "Empty hand"
evaluateHand xs
    | isRoyal xs      = RoyalFlush
    | isStrFlush xs   = StraightFlush
    | isFourKind xs   = FourOfAKind
    | isFullHouse xs  = FullHouse
    | isFlush xs      = Flush
    | isStraight xs   = Straight
    | isThreeKind xs  = ThreeOfAKind
    | isTwoPair xs    = TwoPair
    | isPair xs       = Pair
    | otherwise       = HighCard
    where
        isRoyal xs     = isStrFlush xs && ((maximum (values xs)) == Ace)
        isStrFlush xs  = isFlush xs && isStraight xs
        isFourKind xs  = xOfKind 4 xs
        isFullHouse xs = let list = [length l | l <- group (sort (values xs))]
                         in  2 `elem` list && 3 `elem` list
        isFlush (x:xs) = foldl (\acc y -> if getSuit x /= y then False else acc) True (suits xs)
        isStraight [x] = True
        isStraight xs  = if length (values xs) == length (nub (values xs)) && succ (head (sort (values xs))) `elem` (values xs) then isStraight (tail (sortBy sorting xs)) else False
        isThreeKind xs = xOfKind 3 xs
        isTwoPair xs   = sort [length l | l <- group (sort (values xs))] == [1,2,2]
        isPair xs      = xOfKind 2 xs
        sorting x y    = if getValue x < (getValue y) then LT else if getValue x > (getValue y) then GT else EQ
        xOfKind n xs   = maximum [length l | l <- (group (sort (values xs)))] == n

values :: Hand -> [Value]
values xs = [getValue x | x <- xs]

suits :: Hand -> [Suit]
suits xs = [getSuit x | x <- xs]

highCardValue :: Hand -> Value
highCardValue [] = error "Empty hand"
highCardValue xs = maximum [getValue x | x <- xs]