-- 1. convert data type
UPDATE nashvillehousing
SET SaleDate = DATE_FORMAT(
    STR_TO_DATE(SaleDate, '%M %e, %Y'),
    '%Y-%m-%d'
)
WHERE SaleDate IS NOT NULL
  AND SaleDate <> '';

UPDATE nashvillehousing
SET 
    Acreage = NULLIF(TRIM(Acreage), ''),
    LandValue = NULLIF(TRIM(LandValue), ''),
    BuildingValue = NULLIF(TRIM(BuildingValue), ''),
    TotalValue = NULLIF(TRIM(TotalValue), ''),
    YearBuilt = NULLIF(TRIM(YearBuilt), ''),
    Bedrooms = NULLIF(TRIM(Bedrooms), ''),
    FullBath = NULLIF(TRIM(FullBath), ''),
    HalfBath = NULLIF(TRIM(HalfBath), '');

UPDATE nashvillehousing
SET SalePrice = REPLACE(
                    REPLACE(
                        TRIM(SalePrice),
                        '$', ''
                    ),
                    ',', ''
                );

ALTER TABLE nashvillehousing
MODIFY COLUMN SalePrice DECIMAL(12,2),
MODIFY COLUMN Acreage DECIMAL(10,2),
MODIFY COLUMN LandValue DECIMAL(12,2),
MODIFY COLUMN BuildingValue DECIMAL(12,2),
MODIFY COLUMN TotalValue DECIMAL(12,2),
MODIFY COLUMN YearBuilt INT,
MODIFY COLUMN Bedrooms INT,
MODIFY COLUMN FullBath INT,
MODIFY COLUMN HalfBath INT;

ALTER TABLE nashvillehousing
MODIFY COLUMN SaleDate DATE;

UPDATE nashvillehousing
SET PropertyAddress = NULL
WHERE TRIM(PropertyAddress) = '';

-- 2. update PropertyAddress
SELECT 
    a.ParcelID,
    a.PropertyAddress,
    c.ParcelID,
    c.PropertyAddress,
    IFNULL(a.PropertyAddress, c.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing c
    ON a.ParcelID = c.ParcelID
    AND a.UniqueID <> c.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousing a
JOIN nashvillehousing c
    ON a.ParcelID = c.ParcelID
    AND a.UniqueID <> c.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, c.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- 3. break PropertyAddress into individual columns
SELECT SUBSTRING_INDEX(PropertyAddress, ',', 1) as address,
SUBSTRING_INDEX(PropertyAddress, ',', -1) as city
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD PropertySplitAddress TEXT;

UPDATE nashvillehousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

ALTER TABLE nashvillehousing
ADD PropertySplitCity TEXT;

UPDATE nashvillehousing
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

SELECT SUBSTRING_INDEX(OwnerAddress, ',', -1) as state
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerSplitState TEXT;

UPDATE nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- 4. change Y and N to Yes and No in SoldAsVacant
SELECT DISTINCT SoldAsVacant,
count(*)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM nashvillehousing;

UPDATE nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END;

-- 5. remove duplicates
WITH RowNumCTE AS (
    SELECT
        UniqueID,
        ROW_NUMBER() OVER (
            PARTITION BY
                ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
            ORDER BY UniqueID
        ) AS rownum
    FROM nashvillehousing
)

DELETE n
FROM nashvillehousing n
JOIN RowNumCTE r
    ON n.UniqueID = r.UniqueID
WHERE r.rownum > 1;

-- 6. delete unused columns
SELECT *
FROM nashvillehousing;

ALTER TABLE nashvillehousing
DROP COLUMN PropertyAddress,
DROP COLUMN TaxDistrict;